include Pointer_store_common
module Raw = Pointer_store_raw
module Stream = Pointer_store_stream 

let exists store key = 
  Store.find store key

