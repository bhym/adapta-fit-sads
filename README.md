# adapta-fit-sads
A very rough fork of esg adaptive fits for species abundance distribution.
I changed bits here and there, mainly to formatting and to adhere to more "canonical" R style (i.e. <- for declaration, seq_along(x) instead of 1:length(x))

The main change is in the stepping funtion, that is now adaptive, i.e. changes the step based on the number of species added.
Conceptually, it goes forward one step and checks if the number of species has remained the same.
If that is the case, it automatically matches `x_max` to the abundance of the next OTU.

This is the main change in the code, at the beginning of the `while` cycle

```R
     if (counter > 1 && n <= vec_n[(counter - 1)]) {                             
        x_max <- vec[n + 1]                                                       
        n <- sum(vec <= x_max)                                                    
        vec_n[counter] <- n                                                       
      }                                                                           
      vec_x_max[counter] <- x_max                                                 
      shall_i_continue <- ifelse(n < length(vec), TRUE, FALSE)                    
```
compare with the original:
```R
  x_max = start_x_max + #INSERT
  counter = counter + 1
  vec_x_max[counter] = x_max
```
