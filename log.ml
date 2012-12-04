type level = ERROR | WARNING | AUDIT | DEBUG 

let maxlevel = ref DEBUG

let logfile  = open_out_gen [Open_creat;Open_append] 0o644 "server.log"
let loglock  = Mutex.create () 

let tid () = Thread.(id (self ()))

let prefix level = 
  let t = Unix.localtime (Unix.gettimeofday ()) in 
  Printf.sprintf "%4d/%02d/%02d %02d:%02d:%02d %s [%02X] " 
    (1900 + t.Unix.tm_year) 
    (1 + t.Unix.tm_mon) 
    (t.Unix.tm_mday) 
    (t.Unix.tm_hour)
    (t.Unix.tm_min)
    (t.Unix.tm_sec)
    (match level with 
    | ERROR   -> "FAIL"
    | WARNING -> "WARN"
    | AUDIT   -> "INFO"
    | DEBUG   -> "    ")
    (tid ())

let out level fmt = 
  let print s = 
    if level <= !maxlevel then begin
      Mutex.lock loglock ;
      output_string logfile (prefix level ^ s ^ "\n") ;
      flush logfile ;
      Mutex.unlock loglock 
    end 
  in
  Printf.ksprintf print fmt 

