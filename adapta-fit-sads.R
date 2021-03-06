library(GenSA)

### READING DATASET

## reading tara data
tara_data <- read.csv("#INSERT")

### COMMAND LINE ARGUMENTS

args <- commandArgs(TRUE)

## how many samples are taken in each job
job_number_sample <- as.integer(args[1])

## counter for the initial sample number for a job
start_sample <- as.integer(args[2])

### LOOP OVER SELECTED SAMPLES

## total number of samples
sample_number <- length(colnames(tara_data))
print("SAMPLE NUMBER:")
print(sample_number)

## vector final parameters
final_r <- 0
final_l <- 0
final_k <- 0

## vector final n
final_n <- 0

## vector final x_max value
final_x_max <- 0

## vector final p - value value
final_pvalue <- 0

## vector final modified ks distance
final_mod_ksdist <- 0

## number of boots for p - value calculation
boot_reps <- #INSERT (200)

## loop over selected samples
for (sample_counter in start_sample:(start_sample + job_number_sample - 1)) {
  ### EXTRACTING SAMPLE

  ## finding station and size corresponding to loop counter
  station <- colnames(tara_data)[sample_counter]
  print("---------------------------------------------")
  print(sample_counter)
  print(station)

  ## creating vector of data from a single station and size
  vec <- tara_data[, station]

  ## removing zero - abundances from the vector
  vec <- vec[vec != 0]

  ## order the vector
  vec <- sort(vec)

  ## maximum abundance value
  abund_max <- max(vec)
  ### DECLARATIONS AND PARAMETERS
  ## setting starting value for x_max
  start_x_max <- as.integer("#INSERT") #0

  ## setting end value for x_max
  end_x_max <- as.integer("#INSERT") #10100
  ## initialize x_max
  x_max <- as.integer(0)

  ## initialize counter
  counter <- as.integer(0)

  ## estimated parameters vectors
  vec_estimated_r <- numeric()
  vec_estimated_l <- numeric()
  vec_estimated_k <- numeric()

  ## x_max vector
  vec_x_max <- numeric()

  ## modified KS vector
  vec_ksmod_distance <- numeric()

  ## pvalue vector
  vec_ksmod_pvalue <- numeric()

  ## n vector
  vec_n <- numeric()

  ## logical flag for the while
  shall_i_continue <- TRUE

  ### LOOP OVER x_max
  print("*********")
  name_file_root <- paste("saved_data_", station, sep = "")
  name_file_pdf_interact <- paste(name_file_root, "interact - .pdf", sep = "")
  #off pdf(name_file_pdf_interact, width = 7, height = 11)
  #off par(mfrow = c(2, 1))
  while (shall_i_continue) {
    ## stepping
    x_max <- max(start_x_max, x_max) + #INSERT (50)
    counter <- counter + 1

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

    ## defining distribution parameters
    param_rlk <- numeric(3)

    ## defining function A(r)
    a_func <- function(param_rlk) {
      out <- 0
      for (i in seq_along(vec)) {
        if (vec[i] <= x_max) {
          out <- out + vec[i]
        }
      }
      out <- -1 * (out * param_rlk[1])
      return(out)
    }

    ## defining function N(r, l, k)
    n_func <- function(param_rlk) {
      out <- 0
      for (x in 1:x_max) {
        out <- out + exp(-param_rlk[1] * x) * exp(lgamma(x + param_rlk[2]) -
                                                  lgamma(x + param_rlk[3] + 1)
                                                 )
        }
      return(out)
    }

    ## defining function C(l)
    c_func <- function(param_rlk) {
      out <- 0
      for (i in seq_along(vec)) {
        if (vec[i] <= x_max) {
          out <- out + lgamma(vec[i] + param_rlk[2])
        }
      }
      return(out)
    }

    ## defining function D(k)
    d_func <- function(param_rlk) {
      out <- 0
      for (i in seq_along(vec)) {
        if (vec[i] <= x_max) {
          out <- out + lgamma(vec[i] + param_rlk[3] + 1)
        }
      }
      out <- -out
      return(out)
    }

    ## defiining likelihood
    l_func <- function(param_rlk) {
      out <- 0
      out <- a_func(param_rlk) + - n * log(n_func(param_rlk)) +
             c_func(param_rlk) + d_func(param_rlk)
      return(-out)
    }

    # we raise the upper for r, because at 0.01 it often saturates
    estimated_parameters <- GenSA(c("#INSERT"), l_func,
                                  lower = c("#INSERT"),
                                  upper = c("#INSERT"),
                                  control = list(max.time = 10))$par

    vec_estimated_r[counter] <- estimated_parameters[1]
    vec_estimated_l[counter] <- estimated_parameters[2]
    vec_estimated_k[counter] <- estimated_parameters[3]

    print("************")
    print(paste("x-max: ", x_max))
    print(estimated_parameters)

    ### POST PROCESSING STATISTICS

    ## building the model distribution
    norm_const <- n_func(estimated_parameters)
    model_distr <- numeric()
    for (x in 1:x_max) {
    model_distr[x] <- (exp(-estimated_parameters[1] * x) *
                       exp(lgamma(x + estimated_parameters[2]) -
                           lgamma(x + estimated_parameters[3] +
                                  1)
                           )
                       )  /  norm_const
    }

    ## building model CDF
    model_cdf <- numeric()
    model_cdf[1] <- model_distr[1]
    for (x in 2:x_max) {
    model_cdf[x] <- model_distr[x] + model_cdf[x - 1]
    }

    ## restricting the observations to values <= x_max
    obs_data <- numeric()
    for (i in seq_along(vec)) {
      if (vec[i] <= x_max) {
       obs_data[length(obs_data) + 1] <- vec[i]
      }
    }

    ## building observations distribution
    obs_distr <- numeric(x_max)
    for (i in 1:n) {
      obs_distr[obs_data[i]] <- obs_distr[obs_data[i]] + 1
    }
    obs_distr <- obs_distr / sum(obs_distr)

    ## building observations CDF
    obs_cdf <- numeric()
    obs_cdf[1] <- obs_distr[1]
    for (x in 2:x_max) {
      obs_cdf[x] <- obs_distr[x] + obs_cdf[x - 1]
    }

    ### PLOTTING CDF INTERACTIVELY

    #plotting cdf
    #off plot(model_cdf, pch <- 3, col = 2, log = "xy")
    #off points(obs_cdf, pch <- 5, col = 4)

    ##plotting live ranks boot
    #off r <- sort(obs_data, decreasing = TRUE)
    #off plot(r, log <- "xy")

    ### GOODNESS OF THE FIT TESTS

    ## calculation of modified maximum KS difference among cdf
    diff_vec_mod <- (sqrt((model_cdf - obs_cdf) ^ 2))  /
      (sqrt(model_cdf * (1 - model_cdf))) # when cdf is 1, this is NaN
    vec_ksmod_distance[counter] <- max(diff_vec_mod[is.finite(diff_vec_mod)])

    ### BOOTSTRAPPING

    ### plotting live ranks boot
    #off r <- sort(obs_data, decreasing = TRUE)
    #off r <- sort(vec, decreasing = TRUE)
    #off plot(r, log <- "xy")

    ## vector of ks mod distance for each boot
    vec_ksmod_distance_boot <- numeric()

    ## defining distribution parameters
    param_rlk_boot <- numeric(3)

    ## defining observation boot vector
    vec_boot_obs <- numeric(n)

    ## defining function A_boot(r)
    a_func_boot <- function(param_rlk_boot) {
      out <- 0
      for (i in 1:n) {
      out <- out + vec_boot_obs[i]
      }
      out <- -1 * (out * param_rlk_boot[1])
      return(out)
    }

    ## defining function N_boot(r, l, k)
      n_func_boot <- function(param_rlk_boot) {
      out <- 0
      for (x in 1:x_max) {
        out <- out +
               exp(-param_rlk_boot[1] * x) * exp(lgamma(x + param_rlk_boot[2]) -
                                                 lgamma(x + param_rlk_boot[3]
                                                        + 1
                                                       )
                                                )
      }
      return(out)
    }

    ## defining function C_boot(l)
    c_func_boot <- function(param_rlk_boot) {
      out <- 0
      for (i in 1:n) {
      out <- out + lgamma(vec_boot_obs[i] + param_rlk_boot[2])
      }
      return(out)
    }

    ## defining function D_boot(k)
    d_func_boot <- function(param_rlk_boot) {
      out <- 0
      for (i in 1:n) {
      out <- out + lgamma(vec_boot_obs[i] + param_rlk_boot[3] + 1)
      }
      out <- -out
      return(out)
    }

    ## defiining likelihood_boot
    l_func_boot <- function(param_rlk_boot) {
      out <- 0
      out <- a_func_boot(param_rlk_boot) -
             n * log(n_func_boot(param_rlk_boot)) +
             c_func_boot(param_rlk_boot) +
             d_func_boot(param_rlk_boot)
      return(-out)
    }

    ## bootstrap loop
    for (boot_counter in 1:boot_reps) {

     ## creating synthetic data boot
     vec_boot_obs <- sample(x_max, n, replace = TRUE, model_distr)

     ## estimating parameters single boot
     param_rlk_boot <- GenSA(c(estimated_parameters[1],
                               estimated_parameters[2],
                               estimated_parameters[3]
                               ),
                             l_func_boot,
                             lower = c(0.0, - 0.5, - 0.5),
                             upper = c(0.01, 10.0, 10.0),
                             control = list(max.time = 10)
                             )$par

     ## building the model distribution boot
     norm_const_boot <- n_func_boot(param_rlk_boot)
     model_distr_boot <- numeric()
     for (x in 1:x_max) {
       model_distr_boot[x] <- (exp(-param_rlk_boot[1] * x) *
                               exp(lgamma(x + param_rlk_boot[2]) -
                                   lgamma(x + param_rlk_boot[3] + 1)
                                 )
                               ) /  norm_const_boot
     }

     ## building model CDF_boot
     model_cdf_boot <- numeric()
     model_cdf_boot[1] <- model_distr_boot[1]
     for (x in 2:x_max) {
       model_cdf_boot[x] <- model_distr_boot[x] + model_cdf_boot[x - 1]
     }

     ## building observations boot distribution
     obs_distr_boot <- numeric(x_max)
     for (i in 1:n) {
       obs_distr_boot[vec_boot_obs[i]] <- obs_distr_boot[vec_boot_obs[i]] + 1
     }
     obs_distr_boot <- obs_distr_boot / sum(obs_distr_boot)

     ## building observations CDF_boot
     obs_cdf_boot <- numeric()
     obs_cdf_boot[1] <- obs_distr_boot[1]
     for (x in 2:x_max) {
       obs_cdf_boot[x] <- obs_distr_boot[x] + obs_cdf_boot[x - 1]
     }

     ## calculation of modified maximum KS difference for boot
     diff_vec_mod_boot <- (sqrt((model_cdf_boot - obs_cdf_boot)^2)) /
       (sqrt(model_cdf_boot * (1 - model_cdf_boot))) # when cdf is 1, this isNaN
     vec_ksmod_distance_boot[boot_counter] <-
       max(diff_vec_mod_boot[is.finite(diff_vec_mod_boot)])

     ## plotting live ranks boot
     #off rr <- sort(vec_boot_obs, decreasing = TRUE)
     #off points(rr, col <- 2, log = "xy")
     #off points(r, log <- "xy")

     } ## end boot - reps loop

    ## calculating p - value
    vec_ksmod_pvalue[counter] <- sum(vec_ksmod_distance_boot >=
                                     vec_ksmod_distance[counter])  /  boot_reps

    print(paste("dist:", vec_ksmod_distance[counter]))
    print(paste("pvalue:", vec_ksmod_pvalue[counter]))
    print("************")

  } # end x_max loop

  ### SELECTING FINAL VALUES

  final_r <- NaN
  final_l <- NaN
  final_k <- NaN
  final_x_max <- NaN
  final_pvalue <- NaN
  final_mod_ksdist <- NaN
  final_n <- NaN

  for (i in seq_along(vec_ksmod_pvalue)) {

    if (vec_ksmod_pvalue[i] >= 0.1) {
      final_x_max <- vec_x_max[i]

      final_r <- vec_estimated_r[i]
      final_l <- vec_estimated_l[i]
      final_k <- vec_estimated_k[i]

      final_pvalue <- vec_ksmod_pvalue[i]
      final_mod_ksdist <- vec_ksmod_distance[i]
      final_n <- vec_n[i]
    }
  }

  print("--------------")
  print(paste("x-max:", final_x_max))
  print(paste("r:", final_r))
  print(paste("l:", final_l))
  print(paste("k:", final_k))
  print(paste("KS - distance:", final_mod_ksdist))
  print(paste("p - value:", final_pvalue))
  print("---------------------------------------------")

  ### LOG - BIN HISTO AND PLOT

  ## defining final normalization constant
  final_norm_const <- 0
  if (is.finite(final_x_max)) {
    for (x in 1:final_x_max) {
      final_norm_const <- final_norm_const +
        exp(-final_r * x) * exp(lgamma(x + final_l) - lgamma(x + final_k + 1))
      }
  }

  ## j - max calculation
  j_max <- log2(abund_max) + 2

  ## breaks and normalizing vector declaration
  breaks_vec <- numeric(j_max)
  norm_vec <- numeric(j_max)

  ## breaks vector contruction
  for (j in 1:j_max) {
    breaks_vec[j] <- 2 ^ (j - 1) - 0.5
    norm_vec[j] <- 2 ^ (j - 1)
  }
  name_file_root <- paste("saved_data_", station, sep = "")

  ## removing last element from norm_vec
  norm_vec <- head(norm_vec, - 1)

  ## creating histogram vector
  histo_data <- hist(vec, breaks = breaks_vec, plot = FALSE)
  #off print(histo_data)

  ## plotting in log - log and saving as .pdf
  name_file_pdf <- paste(name_file_root, ".pdf", sep = "")
  pdf(name_file_pdf, width = 7, height = 11)

  par(mfrow = c(2, 1))

  ## fit and log - bin pdf
  plot(histo_data$mids, ((histo_data$counts / norm_vec) /
                         sum(histo_data$counts / norm_vec)
                       ), main = station, log = "xy")

  if (is.finite(final_x_max) & is.finite(final_l)) {
    curve(exp(lgamma(x + final_l)
              - lgamma(x + 1 + final_k)
              ) * exp(-1 * (final_r * x))  /  final_norm_const,
          from = 1, to = final_x_max, add = TRUE)
    abline(v = final_x_max, col = 4)
    legend("topright", legend = c((-1 + final_l - final_k),
                                  final_x_max,
                                  final_pvalue
                                  ), bty = "o")
  }

  if (is.nan(final_x_max) & is.nan(final_l)) {
    legend("topleft", legend = "NO FIT", bty = "n", cex = 3)
  }

  ## rank - plot
  vec <- sort(vec, decreasing = TRUE)
  plot(vec, main = station, log = "xy", xlab = "rank", ylab = "density")
  if (is.finite(final_x_max) & is.finite(final_l)) {
    abline(h = final_x_max, col = 4)
  }

  dev.off()

  ### FINAL VALUES OUPUT FILE WRITING

  name_file_csv <- paste(name_file_root, ".csv", sep = "")
  name_file_data <- paste(name_file_root, ".Rdata", sep = "")

  station_number <- substring(station, 6, 8)
  station_size <- substring(station, 14, 50)
  station_complete <- substring(station, 6, 12)

  estimated_data <- data.frame(station_complete, station_size, final_r, final_l,
                               final_k, final_x_max, final_mod_ksdist,
                               final_pvalue, final_n)

  write.csv(estimated_data, file = name_file_csv)
  save.image(file = name_file_data)
} ## loop all samples
