type handler = Unix.sockaddr -> Pipe.readwrite -> unit

let numlock = Mtx.make "numthreads"
let threads = ref 0 
let version = ref 0 

let describe = function
  | Unix.ADDR_UNIX s -> "UNIX:" ^ s
  | Unix.ADDR_INET (a,i) -> Unix.string_of_inet_addr a ^ ":" ^ string_of_int i 

let stop () = 
  incr version 

let start ~port ~max ~handler = 
  stop () ;
  let myversion = !version in 
  Log.(out AUDIT "Start listener %d" myversion) ;
  let sock = Unix.(socket PF_INET SOCK_STREAM 0) in
  Unix.(setsockopt sock SO_REUSEADDR true) ;
  Unix.(bind sock (ADDR_INET (inet_addr_loopback, port))) ;
  Log.(out AUDIT "... listening on localhost:%d" port) ;
  Unix.(listen sock max) ;

  let incr () = Mtx.use numlock (lazy (incr threads)) in
  let decr () = Mtx.use numlock (lazy (decr threads)) in

  let accept () = 
    let socket, addr = Unix.accept sock in 
    let pipe = new Pipe.readwrite socket in 
    incr () ;
    let _ = Thread.create begin fun () ->
      Log.(out AUDIT "JOIN %s" (describe addr));
      try 
	handler addr pipe ; 
	decr () ;
	Log.(out AUDIT "STOP %s" (describe addr));
      with exn -> 
	decr () ;
	Log.(out ERROR "STOP %s : %s" (describe addr) 
	       (Printexc.to_string exn))
    end () in () 
  in
  
  while !version = myversion do 
    if !threads < max then accept () else Thread.yield () 
  done ;

  Log.(out AUDIT "Stop lister #%d" myversion)  
  
