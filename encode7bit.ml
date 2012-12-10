exception BadInput of exn

let rec length i = 
  if i lsr 7 = 0 then 1 else 1 + length (i lsr 7) 

let to_string i = 
  let n = 
    if i lsr 7 = 0 then 1 else 
      if i lsr 14 = 0 then 2 else 
	if i lsr 21 = 0 then 3 else 
	  if i lsr 27 = 0 then 4 else 5
  in
  let s = String.create n in
  let i = ref i in 
  for j = 0 to n - 2 do 
    s.[j] <- Char.chr ((!i land 0x7F) lor 0x80) ;
    i := !i lsr 7 
  done ;
  s.[n-1] <- Char.chr !i ;
  s

let ok s = 
  let n = String.length s in 
  n >= 1 || n <= 5 && (Char.code s.[n-1]) land 0x80 = 0

let of_prefix s =
  let rec extract i n = 
    let j = Char.code s.[i] in
    let n = n lor ((j land 0x7F) lsl (i * 7)) in
    if j land 0x80 <> 0 then extract (i+1) n else n
  in
  try extract 0 0 with exn -> raise (BadInput exn) 

let of_string s = 
  if not (ok s) then raise (BadInput (Failure "Incorrect input size"));
  of_prefix s

let rec to_channel chan i = 
  if i lsr 7 = 0 then
    output_char chan (Char.chr i) 
  else
    let c = Char.chr ((i land 0x7F) lor 0x80) in
    let _ = output_char chan c in
    to_channel chan (i lsr 7) 

let of_channel chan = 
  let rec extract i n = 
    let j = Char.code (input_char chan) in
    let n = n lor ((j land 0x7F) lsl (i * 7)) in
    if j land 0x80 <> 0 then extract (i+1) n else n
  in
  try extract 0 0 with exn -> raise (BadInput exn)

let of_charStream poll t = 
  let rec extract i n = 
    let j = Char.code (poll t) in
    let n = n lor ((j land 0x7F) lsl (i * 7)) in
    if j land 0x80 <> 0 then extract (i+1) n else n
  in
  extract 0 0
