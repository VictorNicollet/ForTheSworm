open Pointer_store_common

module Meta = Pointer_store_meta
module Name = Pointer_name 

class type server = object
  method save_blob : Blob.t -> Key.t 
  method load_blob : Key.t -> Blob.t option 
end 

let create store server ~name = 
  let key  = Name.hash name in
  let meta = Meta.(to_bytes { kind = `STREAM ; name = name }) in
  let tree = SeqTree.empty in 
  let blob = SeqTree.to_blob tree in 
  let tkey = server # save_blob blob in 
  let data = Key.to_bytes tkey in 
  if Store.create store key ~meta ~data then begin 
    Log.(out AUDIT "%s -> %s (%s)"
	   (Key.to_hex_short key) (Key.to_hex_short tkey) (Name.human_readable name)) ;
    Some key 
  end else None

let add store server key events = 

  let rec save_tree tree = 
    (* Split the tree as many times as necessary (could be a lot, 
       if many events were appended), writing each atomic subtree to the 
       blob store. *)
    match SeqTree.split tree with 
      | `KEEP t -> let blob = SeqTree.to_blob tree in 
		   server # save_blob blob 
      | `SPLIT (left,rightF) -> let lkey = save_tree left in
				let right = rightF lkey in
				save_tree right
  in

  let missing ckey = 
    Log.(out ERROR "Stream tree lost : %s -> %s" 
	   (Key.to_hex_short key) 
	   (Key.to_hex_short ckey)) ;
    `MISSING
  in

  let rec attempt ckey = 

    (* Grab the current tree *)
    match server # load_blob ckey with None -> missing ckey | Some blob -> 
      let tree = SeqTree.of_blob blob in 

      Log.(out DEBUG "Tree loaded, last = %d" (SeqTree.last tree)) ;
    
      (* Append the events to the tree, generating a new tree *)
      let tree = List.fold_left (fun tree event -> SeqTree.add event tree) tree events in 
      let version = SeqTree.last tree in

      (* Save the tree, grab its key *)
      let nkey = save_tree tree in
      
      (* Save the new tree key to the pointer *)
      let result = Store.access store key (fun ~meta chan -> 
	let ckey' = Key.of_channel chan in 
	if ckey = ckey' then 
	  `OK (version,nkey), Some (Key.to_bytes nkey) 
	else
	  `CONFLICT ckey', None
      ) in

      (* Retry if a conflict happens *)
      match result with 
	| Some (`OK (version,nkey)) -> begin
	  Log.(out AUDIT "%s -> %s [%d]"
		 (Key.to_hex_short key) (Key.to_hex_short nkey) version) ;
	  `OK version
	end
	| Some (`CONFLICT ckey') -> attempt ckey'
	| None -> begin 
	  Log.(out AUDIT "Stream pointer disappeared : %s" (Key.to_hex_short key)) ; 
	  `MISSING
	end
  in

  (* Determine the current stored pointer *)
  match Store.load store key Key.of_channel with 
    | Some ckey -> attempt ckey
    | None -> Log.(out AUDIT "Stream pointer not found : %s" (Key.to_hex_short key)) ; `MISSING

exception MissingSubTree

let load store server key ~start ~count = 
  
  let count = if start < 0 then count + start else count in 
  let start = if start < 0 then 0 else start in

  (* This function performs a depth-first, latest-to-oldest traversal of the 
     seqTree, filtered to only return leaves within a range (see SeqTree.range), 
     using its first parameter as a result accumulator and its second parameter
     as the execution stack (to be tail-recursive). *)
  let rec explore acc = function 
    | [] -> List.concat acc
    | [] :: l -> explore acc l 
    | ((k,b,e) :: t1) :: t2 -> 
      match server # load_blob k with 
	| None -> Log.(out ERROR "Stream tree list : %s -> [..] -> %s" 
			 (Key.to_hex_short key) (Key.to_hex_short k)) ; raise MissingSubTree
	| Some blob -> let tree = SeqTree.of_blob blob in 
		       let sub, seq = SeqTree.range tree b e in
		       explore (seq :: acc) (List.rev sub :: t1 :: t2)
  in

  let b = start in
  let e = start + count in 

  (* Load the root, start searching *)
  match Store.load store key Key.of_channel with 
    | None -> Log.(out AUDIT "Stream pointer not found : %s" (Key.to_hex_short key)) ; None
    | Some k -> if count < 1 then Some [] else try Some (explore [] [[k,b,e]]) with 
	| MissingSubTree -> None

let delete store key = 
  Store.delete store key  
