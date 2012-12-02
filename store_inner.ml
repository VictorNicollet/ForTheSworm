type store = string

let filename store key = 
  let hex = Key.to_hex key in 
  let prefix = String.sub hex 0 2 and suffix = String.sub hex 2 38 in
  Filename.concat store (Filename.concat prefix suffix)

let load store key callback = 
  match (try Some (open_in_bin (filename store key)) with _ -> None) with 
    None -> None | Some chan -> 
      try let result = callback chan in 
	  close_in chan ;
	  Some result
      with exn -> close_in chan ; raise exn

let find store key = 
  None <> load store key ignore

let save store key callback = 
  let filename = filename store key in
  let dirname  = Filename.dirname filename in  
  if not (Sys.is_directory (Filename.dirname dirname)) then
    Unix.mkdir (Filename.dirname dirname) 0o700 ;
  if not (Sys.is_directory dirname) then
    Unix.mkdir dirname 0o700 ;
  if not (Sys.file_exists filename) then 
    let chan = open_out_bin filename in 
    ( try callback chan ; close_out chan with exn -> close_out chan ; raise exn )
      

