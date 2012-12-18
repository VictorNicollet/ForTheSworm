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

let ispow2 x = 
  0 = x land (x - 1)

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
      | Leaf _ -> node tree leaf 2 2 
      | Node n when ispow2 n.size -> node tree leaf (n.size+1) (n.cost+1)
      | Pass n when ispow2 n.size -> node tree leaf (n.size+1) (n.cost+1) 
      | Node n -> node n.left (add n.right) (n.size+1) (n.cost+1)
      | Pass n -> pass n.left (add n.right) (n.size+1) (n.cost+1)
    in
    Some (add tree) 

let max_cost = 64

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
        | Leaf l -> (refA,(l.value,l.seq) :: valA) 
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

	
    
	  
