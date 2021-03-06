#' A function to read and re-arrange the data in different ways
#'
#' This internal function imports the data and outputs only those variables that are needed to run the model
#' according to the information provided by the user.
#' @param data A data frame in which to find variables supplied in \code{model.eff} and \code{model.cost}. Among these,
#' effectiveness, cost and treatment indicator (only two arms) variables must always be provided and named 'e', 'c' and 't' respectively. 
#' @param model.eff A formula expression in conventional \code{R} linear modelling syntax. The response must be a health economics
#'  effectiveness outcome ('e') whose name must correspond to that used in \code{data}, and 
#'  any covariates are given on the right-hand side. If there are no covariates, specify \code{1} on the right hand side.
#'  By default, covariates are placed on the "location" parameter of the distribution through a linear model.
#' @param model.cost A formula expression in conventional \code{R} linear modelling syntax. The response must be a health economics
#'  cost outcome ('c') whose name must correspond to that used in \code{data}, and any covariates are given on the right-hand side.
#'  If there are no covariates, specify \code{1} on the right hand side. By default, covariates are placed on the "location" 
#'  parameter of the distribution through a linear model.
#' @param model.me A formula expression in conventional \code{R} linear modelling syntax.  The response must be indicated with the 
#' term 'me'(missing effects) and any covariates used to estimate the probability of missing effects are given on the right-hand side. 
#' If there are no covariates, specify \code{1} on the right hand side. By default, covariates are placed on the "probability" parameter for the missing effects through a logistic-linear model.
#' @param model.mc A formula expression in conventional R linear modelling syntax. The response must be indicated with the 
#' term 'mc'(missing costs) and any covariates used to estimate the probability of missing costs should be given on the right-hand side. 
#' If there are no covariates, specify \code{1} on the right hand side. By default, covariates are placed on the "probability" parameter for the missing costs through a logistic-linear model.
#' @param type Type of missingness mechanism assumed. Choices are Missing At Random (MAR) and Missing Not At Random (MNAR).
#' @keywords read data
#' @importFrom stats na.omit sd as.formula model.matrix model.frame model.response
#' @export
#' @examples
#' \dontrun{
#' #create a data set which respects the requirements specified in "data" (see Arguments)
#' N1 <- 150
#' N2 <- 100
#' m_eff1 <- m_cost1 <- rbinom(N1, 1, 0.25)
#' m_eff2 <- m_cost2 <- rbinom(N2, 1, 0.25)
#' m_cost1 <- m_cost1 <- rbinom(N1, 1, 0.25)
#' m_cost2 <- m_cost2 <- rbinom(N2, 1, 0.25)
#' eff1 <- rnorm(N1, 0.5, 0.5)
#' eff2 <- rnorm(N2, 0.5, 0.5)
#' cost1 <- rnorm(N1, 90, 20)
#' cost2 <- rnorm(N2, 90, 20)
#' 
#' #introduce missingness
#' eff1[m_eff1 == 1] <- NA
#' eff2[m_eff2 == 1] <- NA
#' cost1[m_cost1 == 1] <- NA
#' cost2[m_cost2 == 1] <- NA
#' 
#' #arrange data frame
#' e <- c(eff1, eff2)
#' c <- c(cost1, cost2)
#' m_eff <- c(m_eff1, m_eff2)
#' m_cost <- c(m_cost1, m_cost2)
#' t <- c(t1, t2)
#' data <- data.frame(e ,c, t)
#' 
#' #run the function
#' date_rearranged <- data_read_selection(data = data, model.eff = e ~ 1, model.cost = c ~ 1
#' model.me = me ~ 1, model.mc = mc ~ 1, type = "MAR")
#' }
#' #
#' #


data_read_selection <- function(data, model.eff, model.cost, model.me, model.mc, type = type) {
  if(any(names(data) == "e") == TRUE & any(names(data) == "c") == TRUE) {
    e <- as.name("e")
    c <- as.name("c")
  }
  cov_matrix <- subset(data, select = -c(e, c))
  if(any(is.na(cov_matrix)) == TRUE) {
    stop("no missing covariate or treatment indicator is allowed")
  }
  is.formula<-function (x) { inherits(x, "formula") }
  if(is.formula(model.eff) == FALSE | is.formula(model.cost) == FALSE) {
    stop("model.eff and/or model.cost must be formula objects")
  }
  if(all(names(model.frame(model.eff)) %in% names(data)) == FALSE | 
     all(names(model.frame(model.cost)) %in% names(data)) == FALSE) {
    stop("you must provide names in the formula that correspond to those in the data")
  }
  if("e" %in% labels(terms(model.eff)) | "c" %in% labels(terms(model.cost))) {
    stop("please remove 'e' from the right hand side of model.eff and/or 'c' from the right hand side of model.cost")
  }
  if(names(model.frame(model.eff)[1]) != "e") {
    stop("you must set 'e' as the response in the formula model.eff")
  }
  if("c" %in% names(model.frame(model.eff))) {
    stop("dependence allowed only through the cost model; please remove 'c' from model.eff")
  }
  if(names(model.frame(model.cost)[1]) != "c") {
    stop("you must set 'c' as the response in the formula model.cost")
  }
  if("t" %in% names(model.frame(model.cost)) | "t" %in% names(model.frame(model.eff))) {
    stop("treatment indicator must be provided only in the data. Please remove 't' from 'model.eff' and/or 'model.cost'")
  }
  index_mis_e <- which(is.na(data$e))
  index_mis_c <- which(is.na(data$c))
  data2 <- data
  data$e[is.na(data$e) == TRUE] <- -999999
  data$c[is.na(data$c) == TRUE] <- -999999
  mf_e <- model.frame(formula = model.eff, data = data)
  mf_c <- model.frame(formula = model.cost, data = data)
  terms <- NULL
  x_e <- model.matrix(attr(mf_e, "terms"), data = mf_e)
  x_c <- model.matrix(attr(mf_c, "terms"), data = mf_c)
  if("e" %in% names(mf_c)){
    mf_c$e[index_mis_e] <- NA
  }
  y_e <- model.response(mf_e)
  y_c <- model.response(mf_c)
  y_e[index_mis_e] <- NA
  y_c[index_mis_c] <- NA
  data$e[index_mis_e] <- NA
  data$c[index_mis_c] <- NA
  N1 <- N2 <- c() 
  N1 <- sum(data$t == 1) 
  N2 <- length(data$t) - N1 
  N <- c(N1, N2)
  m_eff <- rep(0, length(data$e))
  m_eff[index_mis_e] <- 1
  m_cost <- rep(0, length(data$c))
  m_cost[index_mis_c] <- 1
  m_eff1 <- m_eff2 <- m_cost1 <- m_cost2 <- c() 
  t1_index <- which(data$t == 1)
  t2_index <- which(data$t == 2)
  eff1 <- y_e[t1_index] 
  eff2 <- y_e[t2_index] 
  eff <- list(eff1, eff2)
  cost1 <- y_c[t1_index] 
  cost2 <- y_c[t2_index] 
  cost <- list(cost1, cost2)
  m_eff1 <- m_eff[t1_index]
  m_eff2 <- m_eff[t2_index]
  m_eff <- list(m_eff1, m_eff2) 
  m_cost1 <- m_cost[t1_index]
  m_cost2 <- m_cost[t2_index]
  m_cost <- list(m_cost1, m_cost2) 
  N1_cc <- N2_cc <- N1_mis <- N2_mis <- c() 
  N1_cc[1] <- length(na.omit(eff1)) 
  N1_cc[2] <- length(na.omit(cost1)) 
  N2_cc[1] <- length(na.omit(eff2)) 
  N2_cc[2] <- length(na.omit(cost2)) 
  N_cc <- cbind(N1_cc, N2_cc) 
  N1_mis <- N1 - N1_cc 
  N2_mis <- N2 - N2_cc 
  N_mis <- cbind(N1_mis, N2_mis) 
  effects <- list(eff1, eff2) 
  costs <- list(cost1, cost2) 
  eff1_cc <- eff2_cc <- cost1_cc <- cost2_cc <- c() 
  eff1_cc <- na.omit(eff1) 
  eff2_cc <- na.omit(eff2) 
  eff_cc <- list(eff1_cc, eff2_cc) 
  cost1_cc <- na.omit(cost1) 
  cost2_cc <- na.omit(cost2) 
  cost_cc <- list(cost1_cc, cost2_cc)
  cov1_e <- as.data.frame(x_e[t1_index, ])
  names(cov1_e) <- colnames(x_e)
  cov2_e <- as.data.frame(x_e[t2_index, ])
  names(cov2_e) <- colnames(x_e)
  cov_e <- list(cov1_e, cov2_e)
  x_c_hold <- x_c
  if("e" %in% colnames(x_c_hold)) {
    x_c <- subset(x_c_hold, select = -c(e))
  }
  cov1_c <- as.data.frame(x_c[t1_index, ])
  names(cov1_c) <- colnames(x_c)
  cov2_c <- as.data.frame(x_c[t2_index, ])
  names(cov2_c) <- colnames(x_c)
  cov_c <- list(cov1_c, cov2_c)
  binary_check <- function(x) { 
    length(unique(x)) <= 2 
  } 
  cove <- list(cov1_e, cov2_e) 
  mean_cov_e <- list(apply(as.matrix(cov1_e), 2, mean), apply(as.matrix(cov2_e), 2, mean))
  covc <- list(cov1_c, cov2_c) 
  mean_cov_c <- list(apply(as.matrix(cov1_c), 2, mean), apply(as.matrix(cov2_c), 2, mean))
  check1_e <- which(apply(cov1_e, 2, binary_check)) 
  check1_e <- check1_e[-1]
  check2_e <- which(apply(cov2_e, 2, binary_check)) 
  check2_e <- check2_e[-1]
  check1_c <- which(apply(cov1_c, 2, binary_check)) 
  check1_c <- check1_c[-1]
  check2_c <- which(apply(cov2_c, 2, binary_check)) 
  check2_c <- check2_c[-1]
  if(any(unlist(lapply(mf_e, is.factor))) == TRUE) {
    mean_cov_e[[1]][check1_e] <- 1
    mean_cov_e[[2]][check2_e] <- 1
  }
  if(any(unlist(lapply(mf_c, is.factor))) == TRUE) {
    mean_cov_c[[1]][check1_c] <- 1
    mean_cov_c[[2]][check2_c] <- 1
  }
  data2$e[is.na(data2$e) == TRUE] <- -999999
  data2$c[is.na(data2$c) == TRUE] <- -999999
  data2$me <- c(m_eff1, m_eff2)
  data2$mc <- c(m_cost1, m_cost2)
  if(is.formula(model.me) == FALSE | is.formula(model.mc) == FALSE) {
    stop("model.me and/or model.mc must be formula objects")
  }
  if(all(names(model.frame(model.me, data = data2)) %in% names(data2)) == FALSE | 
     all(names(model.frame(model.mc, data = data2)) %in% names(data2)) == FALSE) {
    stop("you must provide names in the formula that correspond to those in the data")
  }
  if(names(model.frame(model.me, data = data2)[1]) != "me") {
    stop("you must set 'me' as the response in the formula model.me")
  }
  if(names(model.frame(model.mc, data = data2)[1]) != "mc") {
    stop("you must set 'mc' as the response in the formula model.mc")
  }
  if("t" %in% names(model.frame(model.mc, data = data2)) | "t" %in% names(model.frame(model.me, data = data2))) {
    stop("treatment indicator must be provided only in the data. Please remove 't' from 'model.me' and/or 'model.mc'")
  }
  if("c" %in% names(model.frame(model.me, data = data2)) | "e" %in% names(model.frame(model.mc, data = data2))) {
    stop("please remove 'e' from model.mc and/or remove 'c' from model.me")
  }
  zf_e <- model.frame(formula = model.me, data = data2)
  zf_c <- model.frame(formula = model.mc, data = data2)
  z_e <- model.matrix(attr(zf_e, "terms"), data = zf_e)
  z_c <- model.matrix(attr(zf_c, "terms"), data = zf_c)
  z_e_hold <- z_e
  if("e" %in% colnames(z_e_hold)) {
    z_e <- subset(z_e_hold, select = -c(e))
  }
  covz1_e <- as.data.frame(z_e[t1_index, ])
  names(covz1_e) <- colnames(z_e)
  covz2_e <- as.data.frame(z_e[t2_index, ])
  names(covz2_e) <- colnames(z_e)
  covz_e <- list(covz1_e,covz2_e)
  covze <- list(covz1_e,covz2_e) 
  mean_covz_e <- list(apply(as.matrix(covz1_e), 2, mean), apply(as.matrix(covz2_e), 2, mean))
  checkz1_e <- which(apply(covz1_e, 2, binary_check)) 
  checkz1_e <- checkz1_e[-1]
  checkz2_e <- which(apply(covz2_e, 2, binary_check)) 
  checkz2_e <- checkz2_e[-1]
  if(any(unlist(lapply(zf_e, is.factor))) == TRUE) {
    mean_covz_e[[1]][checkz1_e] <- 1
    mean_covz_e[[2]][checkz2_e] <- 1
  }
  names(covz_e) <- names(mean_covz_e) <- c("Control", "Intervention")
  z_c_hold <- z_c
  if("c" %in% colnames(z_c_hold)) {
    z_c <- subset(z_c_hold, select = -c(c))
  }
  covz1_c <- as.data.frame(z_c[t1_index, ])
  names(covz1_c) <- colnames(z_c)
  covz2_c <- as.data.frame(z_c[t2_index, ])
  names(covz2_c) <- colnames(z_c)
  covz_c <- list(covz1_c,covz2_c)
  covzc <- list(covz1_c,covz2_c) 
  mean_covz_c <- list(apply(as.matrix(covz1_c), 2, mean), apply(as.matrix(covz2_c), 2, mean))
  checkz1_c <- which(apply(covz1_c, 2, binary_check)) 
  checkz1_c <- checkz1_c[-1]
  checkz2_c <- which(apply(covz2_c, 2, binary_check)) 
  checkz2_c <- checkz2_c[-1]
  if(any(unlist(lapply(zf_c, is.factor))) == TRUE) {
    mean_covz_c[[1]][checkz1_c] <- 1
    mean_covz_c[[2]][checkz2_c] <- 1
  }
  names(covz_c) <- names(mean_covz_c) <- c("Control", "Intervention")
  names(cov_e) <- names(cov_c) <- names(mean_cov_e) <- names(mean_cov_c) <- c("Control", "Intervention")
  names(m_eff) <- names(m_cost) <- c("Control", "Intervention")
  names(effects) <- names(costs) <- names(eff_cc) <- names(cost_cc) <- c("Control", "Intervention")
  data_raw <- list("raw_effects" = effects, "raw_costs" = costs, "raw_effects_cc" = eff_cc, "raw_costs_cc" = cost_cc, "arm_lengths" = N, 
                   "arm_lengths_cc" = N_cc, "arm_missing_data" = N_mis, "missing_effects" = m_eff, "missing_costs" = m_cost, 
                   "covariates_effects" = cov_e, "covariates_costs" = cov_c, "mean_cov_effects" = mean_cov_e, "mean_cov_costs" = mean_cov_c, 
                   "covariates_missing_effects" = covz_e, "mean_cov_missing_effects" = mean_covz_e, "covariates_missing_costs" = covz_c, 
                   "mean_cov_missing_costs" = mean_covz_c, "data_ind" = data2) 
  return(data_raw) 
}


