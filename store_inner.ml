type store = string

let filename ?(meta=false) store key = 
  let hex = Key.to_hex key in 
  let prefix = String.sub hex 0 2 and suffix = String.sub hex 2 38 in
  let file = Filename.concat store (Filename.concat prefix suffix) in
  if meta then file ^ ".meta" else file 

let load store key ?meta callback = 
  match (try Some (open_in_bin (filename ?meta store key)) with _ -> None) with 
    None -> None | Some chan -> 
      try let result = callback chan in 
	  close_in chan ;
	  Some result
      with exn -> close_in chan ; raise exn

let find store key = 
  None <> load store key ignore

let save store key ?meta ?(overwrite=false) callback = 
  let filename = filename ?meta store key in
  let dirname  = Filename.dirname filename in  
  let dirname' = Filename.dirname dirname in 
  (try ignore (Sys.is_directory dirname') with _ -> Unix.mkdir dirname' 0o700) ;
  (try ignore (Sys.is_directory dirname ) with _ -> Unix.mkdir dirname  0o700) ;
  if overwrite || not (Sys.file_exists filename) then 
    let chan = open_out_bin filename in 
    ( try callback chan ; close_out chan with exn -> close_out chan ; raise exn )
      
let delete store key = 
  let filename = filename store key in 
  if Sys.file_exists filename then 
    Sys.remove filename 
