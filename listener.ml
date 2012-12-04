type handler = Unix.sockaddr -> SocketStream.read -> SocketStream.write -> unit

let numlock = Mutex.create () 
let threads = ref 0 
let version = ref 0 

let stop () = 
  incr version 

let start ~port ~max handler = 
  stop () ;
  let myversion = !version in 
  let sock = Unix.(socket PF_INET SOCK_STREAM 0) in
  Unix.(setsockopt sock SO_REUSEADDR true) ;
  Unix.(bind sock (ADDR_INET (inet_addr_loopback, port))) ;
  Unix.(listen sock max) ;

  let incr () = 
    Mutex.lock numlock ;
    incr threads ;
    Mutex.unlock numlock ;
  in

  let decr () = 
    Mutex.lock numlock ;
    decr threads ;
    Mutex.unlock numlock ; 
  in    

  let accept () = 
    let socket, addr = Unix.accept sock in 
    let read = new SocketStream.read socket in 
    let write = new SocketStream.write socket in 
    incr () ;
    let _ = Thread.create begin fun () ->
      try handler addr read write ; decr () 
      with _ -> decr () 
    end () in () 
  in
  
  while !version = myversion do 
    if !threads < max then accept () else Thread.yield () 
  done 
  
