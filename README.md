# adapta-fit-sads
A very rough fork of esg adaptive fits for species abundance distribution.
I changed bits here and there, mainly to increase readability and to adhere to more "canonical" R style (i.e. <- for declaration, seq_along(x) instead of 1:length(x))

The main change is in the stepping funtion, that is now adaptive, i.e. changes the step based on the number of species added.
Conceptually, it goes forward one step and checks if the number of species has remained the same.
If that is the case, it automatically matches `x_max` to the abundance of the next OTU.

This is the main change in the code, at the beginning of the `while` cycle

```R  
  while (shall_i_continue) {                                                    
    ## calculating n == n(x_max)                                                
    n <- sum(vec <= x_max)                                                      
    vec_n[counter] <- n                                                         
                                                                                  
    if (counter > 1 && n <= vec_n[(counter - 1)]) {                             
      x_max <- vec[n + 1]                                                       
      n <- sum(vec <= x_max)                                                    
      vec_n[counter] <- n                                                       
    }                                                                           
    
    print("NUMBER OF DATA POINTS")                                              
    print(n)                 

    vec_x_max[counter] <- x_max                                                 
    shall_i_continue <- ifelse(n < length(vec), TRUE, FALSE)   
```
compare with the original:
```R
while (x_max <= end_x_max){

        ## calculating n == n(x_max)
        n = sum(vec <= x_max)
        vec_n[counter] = n
        
        print('NUMBER OF DATA POINTS')
        print(n)
   
        vec_x_max[counter] = x_max
```
