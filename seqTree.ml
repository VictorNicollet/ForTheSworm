type 'a leaf = { value : 'a ; seq : int }

type ('l,'r) node = {
  left  : 'l ;
  right : 'r ;
  size  : int ;
  cost  : int ;
}

type 'a tree = 
  | Leaf of 'a leaf
  | Node of ('a tree,'a tree) node
  | Pass of (Key.t  ,'a tree) node

type 'a t = 'a tree option

let empty = None

let ispow2 x = 
  0 = x land (x - 1)

let rec lastseq = function 
  | Leaf l -> l.seq
  | Node n -> lastseq n.right
  | Pass n -> lastseq n.right

(* Last should return the same as lastseq for 
   root trees (and should not be called on subtrees). 
*)
let last = function 
  | None -> -1 
  | Some (Leaf l) -> l.seq
  | Some (Node n) -> n.size - 1
  | Some (Pass n) -> n.size - 1 

let cost = function 
  | Leaf l -> 1
  | Node n -> n.cost
  | Pass n -> n.cost 

let size = function 
  | Leaf l -> 1
  | Node n -> n.size
  | Pass n -> n.size

let node l r s c = 
  Node { left = l ; right = r ; size = s ; cost = c }

let pass l r s c = 
  Pass { left = l ; right = r ; size = s ; cost = c }

let add value tree = 
  let leaf = Leaf { value ; seq = last tree + 1 } in
  match tree with None -> Some leaf | Some tree ->
    let rec add = function 
      | Leaf l -> node (Leaf l) leaf 2 2 
      | Node n when ispow2 n.size -> node (Node n) leaf (n.size+1) (n.cost+1)
      | Pass n when ispow2 n.size -> node (Pass n) leaf (n.size+1) (n.cost+1) 
      | Node n -> node n.left (add n.right) (n.size+1) (n.cost+1)
      | Pass n -> pass n.left (add n.right) (n.size+1) (n.cost+1)
    in
    Some (add tree) 

let max_cost = 237

let split = function
  | None -> `KEEP None
  | Some tree -> 
    let rec aux = function 
      | Node n when n.cost >= max_cost -> 
	let left = n.left in 
	let cost = cost n.right in
	let right key = pass key n.right n.size cost in
	`SPLIT (left, right) 
      | Pass n -> 
	let sub = aux n.right in 
	begin match sub with 
	| `KEEP _ -> sub 
	| `SPLIT (left, right) ->
	  let cost = n.cost - cost left in 
	  let right key = pass n.left (right key) n.size cost in
	  `SPLIT (left, right)
	end
      | other -> `KEEP other
    in
    match aux tree with 
    | `KEEP tree -> `KEEP (Some tree) 
    | `SPLIT (left,right) -> 
      let right key = Some (right key) in
      `SPLIT (Some left, right) 

let range tree b e = 
  match tree with None -> [], [] | Some tree ->
    let rec aux b e refA valA = 
      if b >= e then fun _ -> (refA,valA) else function 
        | Leaf l -> (refA,l.value :: valA) 
	| Node n -> auxnode b e refA valA n
	| Pass n -> auxpass b e refA valA n
    and auxnode b e refA valA n =
      let lsize = size n.left in 
      let refA, valA = 
	if e > lsize then aux (max 0 (b-lsize)) (e-lsize) refA valA n.right
	else refA, valA
      in
      if b < lsize then aux b (min lsize e) refA valA n.left 
      else refA, valA
    and auxpass b e refA valA n = 
      let lsize = n.size - (size n.right) in
      let refA, valA = 
	if e > lsize then aux (max 0 (b-lsize)) (e-lsize) refA valA n.right
	else refA, valA
      in
      if b < lsize then ((n.left,b,min lsize e)::refA,valA) 
      else refA, valA
    in
    let b = max b 0 in
    let e = min e (size tree) in
    aux b e [] [] tree

exception ParseError

let to_blob = function 
  | None -> Blob.make ""
  | Some tree ->

    (* Extract all keys from the tree. Duplicates might
       happen, so use a hashtable to create a key -> int 
       mapping that will be turned into an array later.
    *) 
    let keyhash = Hashtbl.create max_cost in
    let keys = ref [] in 
    let addkey key = 
      try Hashtbl.find keyhash key with Not_found -> 
	let n = Hashtbl.length keyhash in
	keys := key :: !keys ;
	Hashtbl.add keyhash key n ; n
    in 

    (* Writing to the buffer. *)
    let buf = Buffer.create 1000 in
    let putc c = Buffer.add_char   buf c in
    let puti i = Buffer.add_string buf (Encode7bit.to_string i) in
    let putk k = puti (addkey k) in   
 
    (* We save the size and starting position, because we
       will need these to read back the leaf "seq" fields.
    *)
    let size = size tree in 
    puti (size) ;
    puti (lastseq tree - size + 1) ;

    (* Recursive function for writing down the tree. This will use 
       up at least two bytes per leaf, which means the average leaf
       size is about 22 bytes (when counting the SHA1 keys). As such,
       a max-cost tree costs 237x22 = 5214 bytes.
    *)
    let rec write = function 
      | Leaf l -> putk l.value 
      | Node n -> putc 'N' ; write n.left ; write n.right
      | Pass n -> putc 'P' ; putk n.left ; write n.right
    in

    write tree ;
 
    let data = Buffer.contents buf in 
    let keys = Array.of_list (List.rev !keys) in

    Blob.make ~keys data 

let log2 n = 
  let n, s = if n lsr 16 <> 0 then n lsr 16, 16    else n, 0 in
  let n, s = if n lsr 8  <> 0 then n lsr 8,  s + 8 else n, s in 
  let n, s = if n lsr 4  <> 0 then n lsr 4,  s + 4 else n, s in 
  let n, s = if n lsr 2  <> 0 then n lsr 2,  s + 2 else n, s in
  if n lsr 1  <> 0 then s + 1 else s
    
let of_blob blob = 
  let keys = Blob.keys blob in 
  let data = Blob.data blob in 
  let m    = String.length data in 
  let kn   = Array.length keys in 

  if m = 0 then None else 
    
    let pos = ref 0 in
    let readc () = if !pos >= m then raise ParseError else let c = data.[!pos] in incr pos ; c in
    let readi () = Encode7bit.of_charStream readc () in
    let readk () = 
      let i = readi () in
      if i < 0 || i >= kn then raise ParseError ; 
      keys.(i) 
    in
    
    let size  = readi () in
    let start = readi () in
    
    let rec read size start = 
      if size = 1 then 
	Leaf { value = readk () ; seq = start } 
      else 
	let lsize  = if ispow2 size then size / 2 else 1 lsl (log2 size) in
	let rsize  = size - lsize in
	let rstart = start - lsize in
	match readc () with 
	  | 'N' -> let l = read lsize start in
		   let r = read rsize rstart in
		   node l r size (cost l + cost l) 
	  | 'P' -> let k = readk () in
		   let r = read rsize rstart in
		   pass k r size (cost r) 
	  |  _  -> raise ParseError
	  
    in
    
    Some (read size start) 
      
