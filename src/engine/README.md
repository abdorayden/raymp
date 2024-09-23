# RMP Engine

. this engine will run rmp scripts <br>
. rmp script it's configuration script language work in raymp music player <br>
1. configure ui and designe of the software 
2. controle windows 
3. controle colours
4. add plugins 

- [ ] Parse syntax file
- [ ] create vim mode for highlight rmp syntax
- [ ] build standerd library to controle terminal 
- [ ] build hight level library for creating and design boxes and access internet
- [ ] recreate raymp design using rmp script as default style 
- [ ] build plugin manager to manage plugins 


# Examples of rmp syntax 
```rust
# this is a comment

# rust import libs style
use core::{window_size , pathlib}
use core::{Box , Line , Col , Keys}
use platform::os
use net::http

# for importing local files 
use local::filename

if <condition>
    <code>
else
    <code>
endif

set Keys::explorer  q # change explorer key to q

let t = 5 # define variable

# define functions
fun! foo(bar)
    <code>
endfun
```

this engine will run rmp script's for having wonderfull music player experience<br>
if you see this project is usefull you can [cuntribute](https://github.com/abdorayden/raymp/blob/master/CONTRIBUTIONS.md) it
