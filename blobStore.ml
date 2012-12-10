type store = Store.store

let save store blob = 
  let key   = Blob.hash blob in 
  let bytes = Blob.to_bytes blob in 
  Store.save store key bytes ;
  key

let load store key = 
  Store.load store key Blob.of_channel 

let find store key = 
  Store.find store key 
