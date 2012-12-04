type t = Sha1.t

let short k = 
  let hex = Sha1.to_hex k in 
  String.sub hex 0 4 ^ ".." ^ String.sub hex 35 4
