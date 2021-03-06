#' Full Bayesian Models to handle missingness in Health Economic Evaluations (Hurdle Models)
#' 
#' Full Bayesian cost-effectiveness models to handle missing data in the outcomes using Hurdle models
#' under a variatey of alternative parametric distributions for the effect and cost variables. Alternative
#' assumptions about the mechanisms of the structural values are also implemented. The analysis is performed using the \code{BUGS} language, 
#' which is implemented in \code{JAGS} using the functions \code{\link[R2jags]{jags}}. The output is stored in an object of class 'missingHE'.
#' 
#' @param data A data frame in which to find variables supplied in \code{model.eff}, \code{model.cost} (model formulas for effects and costs) 
#' and \code{model.se}, \code{model.sc} (model formulas for the structural effect and cost models) . Among these,
#' effectiveness, cost and treatment indicator (only two arms) variables must always be provided and named 'e', 'c' and 't' respectively. 
#' @param model.eff A formula expression in conventional \code{R} linear modelling syntax. The response must be a health economics
#'  effectiveness outcome ('e') whose name must correspond to that used in \code{data}, and 
#'  any covariates are given on the right-hand side. If there are no covariates, specify \code{1} on the right hand side.
#'  By default, covariates are placed on the "location" parameter of the distribution through a linear model.
#' @param model.cost A formula expression in conventional \code{R} linear modelling syntax. The response must be a health economics
#'  cost outcome ('c') whose name must correspond to that used in \code{data}, and any covariates are given on the right-hand side.
#'  If there are no covariates, specify \code{1} on the right hand side. By default, covariates are placed on the "location" 
#'  parameter of the distribution through a linear model. A joint bivariate distribution for effects and costs can be specified by
#'  including 'e' in the model for the costs.
#' @param model.se A formula expression in conventional \code{R} linear modelling syntax.  The response must be indicated with the 
#' term 'se'(structural effects) and any covariates used to estimate the probability of structural effects are given on the right-hand side. 
#' If there are no covariates, specify \code{1} on the right hand side. By default, covariates are placed on the "probability" parameter for the structural effects through a logistic-linear model.
#' @param model.sc A formula expression in conventional \code{R} linear modelling syntax. The response must be indicated with the 
#' term 'sc'(structural costs) and any covariates used to estimate the probability of structural costs should be given on the right-hand side. 
#' If there are no covariates, specify \code{1} on the right hand side. By default, covariates are placed on the "probability" parameter for the structural costs through a logistic-linear model.
#' @param se Structural value to be found in the effect data defined in \code{data}. If set to \code{NULL}, 
#' no structural value is chosen and a standard model for the effects is run.
#' @param sc Structural value to be found in the cost data defined in \code{data}. If set to \code{NULL}, 
#' no structural value is chosen and a standard model for the costs is run.
#' @param type Type of structural value mechanism assumed. Choices are Structural Completely At Random (SCAR),
#' and Structural At Random (SAR).
#' @param dist_e distribution assumed for the effects. Current available chocies are: Normal ('norm') or Beta ('beta').
#' @param dist_c distribution assumed for the costs. Current available chocies are: Normal ('norm'), Gamma ('gamma') or LogNormal ('lnorm')
#' @param save_model Logical. If \code{save_model} is \code{TRUE} a \code{txt} file containing the model code is printed
#'  in the current working directory.
#' @param prob A numeric vector of probabilities within the range (0,1), representing the upper and lower
#'  CI sample quantiles to be calculated and returned for the imputed values.
#' @param n.chains Number of chains.
#' @param n.burnin Number of warmup iterations.
#' @param n.iter Number of iterations.
#' @param n.thin Thinning interval.
#' @param inits A list with elements equal to the number of chains selected; each element of the list is itself a list of starting values for the
#' \code{JAGS} model, or a function creating (possibly random) initial values. If \code{inits} is \code{NULL}, \code{JAGS}
#'  will generate initial values for all the model parameters.
#' @param prior A list containing the hyperprior values provided by the user. Each element of this list must be a vector of length two
#' containing the user-provided hyperprior values and must be named with the name of the corresponding parameter. For example, the hyperprior
#' values for the mean effect parameter can be provided using \code{prior=list('mu.prior.e'=c(0,1))}.
#' For more information about how to provide prior hypervalues for different types of parameters and models see details. 
#' If \code{prior} is set to 'default', the default values will be used.  
#' @param ... additional input parameters provided by the user. Examples are \code{d_e} and \code{d_c} which should be binary indicator vectors
#' with length equal to the number of rows in \code{data}. By default these variables are constructed in the function based on the observed data
#' but it is possible for  the user to directly provide them as a means to explore some Structural Not At Random (SNAR) mechanism assumptions about 
#' either or both the effects and costs. Individuals whose corresponding indicator value is set to \code{1} or \code{0} will be respectively 
#' associated with the structural or non-structural component. Other additional arguments contained in the function \code{\link[BCEA]{bcea}} can be provided. 
#' @return An object of the class 'missingHE' containing the following elements
#' \describe{
#'   \item{data_set}{A list containing the original data set provided in \code{data} (see Arguments), the number of observed and missing individuals 
#'   , the total number of individuals by treatment arm and the indicator vectors for the structural values}
#'   \item{model_output}{A list containing the output of a \code{JAGS} model generated from the functions \code{\link[R2jags]{jags}}}
#'   \item{mean_effects}{A matrix with \code{nsim} rows and \code{2} columns containing the posterior samples for the mean effect parameters in the
#'   treatment arms}
#'   \item{mean_costs}{A matrix with \code{nsim} rows and \code{2} columns containing the posterior samples for the mean cost parameters in the
#'   treatment arms}
#'   \item{sd_effects}{A matrix with \code{nsim} rows and \code{2} columns containing the posterior samples for the standard 
#'   deviation effect parameters in the treatment arms}
#'   \item{sd_costs}{A matrix with \code{nsim} rows and \code{2} columns containing the posterior samples for the standard 
#'   deviation cost parameters in the treatment arms}
#'   \item{imputed}{A list containing the the posterior samples for the imputed individuals in each arm and for each outcome.
#'   The stored imputed values represent the mean and the upper and lower quantiles of the posterior distribution for the
#'   missing individuals according to the values defined in \code{prob} (see Arguments)}
#'   \item{type}{A character variable that indicate which type of structural value mechanism has been used to run the model, 
#'   either \code{SCAR} or \code{SAR} (see details)}
#' }
#' @seealso \code{\link[R2jags]{jags}}, \code{\link[BCEA]{bcea}}
#' @keywords CEA JAGS missing data Hurdle models
#' @importFrom stats model.frame 
#' @details Depending on the distributional assumptions specified for the outcome variables in the arguments \code{dist_e} and
#' \code{dist_c} and the type of structural value mechanism assumed in the argument \code{type}, different types of hurdle models
#' are built and run in the background by the function \code{hurdle}. These are mixture models defined by two components: the first one
#' is a mass distribution at the spike, while the second is a parametric model applied to the natural range of the relevant variable.
#' Usually, a logistic regression is used to estimate the probability of incurring a "structural" value (e.g. 0 for the costs, or 1 for the
#' effects); this is then used to weigh the mean of the "non-structural" values estimated in the second component. A simple example can be used
#' to show how Hurdle models are specified. 
#' Consider a data set comprising a response variable \eqn{y} and a set of centered covariate \eqn{X_j}.Specifically, for each subject in the trial \eqn{i = 1,...,n}
#' we define an indicator variable \eqn{d_i} taking value \code{1} if the \eqn{i}-th individual is associated with a structural value and \code{0} otherwise.
#' This is modelled as:
#' \deqn{d_i ~ Bernoulli(\pi_i)}
#' \deqn{logit(\pi_i) = \gamma_0 + \sum\gamma_j X_j}
#' where
#' \itemize{
#' \item \eqn{\pi_i} is the individual probability of a structural value in \eqn{y}
#' \item \eqn{\gamma_0} represents the marginal probability of a structural value in \eqn{y} on the logit scale.
#' \item \eqn{\gamma_j} represents the impact on the probability of a structural value in \eqn{y} of the centered covariates \eqn{X_j}.
#' }
#' 
#' When \eqn{\gamma_j = 0} the model assumes a 'SCAR' mechanism, while when \eqn{\gamma_j != 0} the mechanism is 'SAR'.
#' For the parameters indexing the structural value model, the default prior distributions assumed are the following:
#' \itemize{
#' \item \eqn{\gamma_0 ~ Logisitc(0, 1)}
#' \item \eqn{\gamma_j ~ Normal(0, 0.0001)}
#' }
#' When user-defined hyperprior values are supplied via the argument \code{prior} in the function \code{hurdle}, the elements of this list (see Arguments)
#' must be vectors of length \code{2} containing the user-provided hyperprior values and must take specific names according to the parameters they are associated with. 
#' Specifically, the names accepted by \strong{missingHE} are the following:
#' \itemize{
#' \item location parameters \eqn{\alpha_0, \beta_0}: "mean.prior.e"(effects) and/or "mean.prior.c"(costs)
#' \item auxiliary parameters \eqn{\sigma}: "sigma.prior.e"(effects) and/or "sigma.prior.c"(costs)
#' \item covariate parameters \eqn{\apha_j, \beta_j}: "alpha.prior"(effects) and/or "beta.prior"(costs)
#' \item marginal probability of structural values \eqn{\gamma_0}: "p.prior.e"(effects) and/or "p.prior.c"(costs)
#' \item covariate parameters in the model of the structural values \eqn{\gamma_j} (if covariate data provided): "gamma.prior.e"(effects) and/or "gamma.prior.c"(costs)
#' } 
#' For simplicity, here we have assumed that the set of covariates \eqn{X_j} used in the models for the effects/costs and in the 
#' model of the structural effect/cost values is the same. However, it is possible to specify different sets of covariates for each model
#' using the arguments in the function \code{hurdle} (see Arguments).
#' 
#' @author Andrea Gabrio
#' @references
#' Ntzoufras I. (2009). \emph{Bayesian Modelling Using WinBUGS}, John Wiley and Sons.
#' 
#' Daniels, MJ. Hogan, JW. (2008). \emph{Missing Data in Longitudinal Studies: strategies for Bayesian modelling and sensitivity analysis}, CRC/Chapman Hall.
#' 
#' Baio, G.(2012). \emph{Bayesian Methods in Health Economics}. CRC/Chapman Hall, London.
#' 
#' Gelman, A. Carlin, JB., Stern, HS. Rubin, DB.(2003). \emph{Bayesian Data Analysis, 2nd edition}, CRC Press.
#' 
#' Plummer, M. \emph{JAGS: A program for analysis of Bayesian graphical models using Gibbs sampling.} (2003).
#' @export
#'
#' @examples
#'#Simple example to simulate and analyse a data set
#'#Define the number of individuals fer treatment arm
#'N1 <- 150
#'N2 <- 100
#'
#'#Simulate data from normal distributions for both arms
#'eff1 <- rnorm(N1, 0.5, 0.5)
#'eff2 <- rnorm(N2, 0.5, 0.5)
#'cost1 <- rnorm(N1, 90, 20)
#'cost2 <- rnorm(N2, 90, 20)
#'
#'#introduce structural values
#'#ones for the effects
#'se = 1
#'eff1[1:10] <- 1
#'eff2[1:10] <- 1
#'
#'#zeros for the costs
#'sc = 0
#'cost1[1:10] <- 0
#'cost2[1:10] <- 0
#'
#'#add missing values
#'eff1[20:30] <- NA
#'eff2[20:30] <- NA
#'cost1[20:30] <- NA
#'cost2[20:30] <- NA
#'
#'#Create treatment arm indicators
#'t1 <- rep(1, length(eff1))
#'t2 <- rep(2, length(eff2))
#'
#'#Combine variables and define a data set
#'e <- c(eff1, eff2)
#'c <- c(cost1, cost2)
#'t <- c(t1, t2)
#'data <- data.frame(e, c, t)
#'
#'#Run the model using the hurdle function assuming a SCAR mechanism
#'x <- hurdle(data = data, model.eff = e ~ 1, model.cost = c ~ 1, 
#'model.se = se ~ 1, model.sc = sc ~ 1, se = 1, sc = 0, 
#'dist_e = "norm", dist_c = "norm", type = "SCAR")
#'
#'#print the results of the JAGS model
#'print(x)
#'#
#'
#'#use information criteria to assess model fit
#'pic <- pic(x, criterion = "dic", module = "total")
#'#
#'
#'#Assess model convergence using graphical tools
#'#Produce histograms of the posterior samples for the mean effect
#'#parameters in the two treatment arms. 
#'diagnostic(x, type = "histogram", param = "mu.e")
#'#
#'
#'#Compare observed outcome data with imputations from the model
#'# (posteiror means and credible intervals)
#'plot(x, class = "scatter", outcome = "all")
#'#
#'
#'#Summarise the CEA information from model results
#'summary(x)
#'#
#'#


hurdle <- function(data, model.eff, model.cost, model.se = se ~ 1, model.sc = sc ~ 1, se = 1, sc = 0, 
                   dist_e, dist_c, type, prob = c(0.05, 0.95), n.chains = 2, n.iter = 20000, 
                   n.burnin = floor(n.iter / 2), inits = NULL, n.thin = 1, save_model = FALSE, prior = "default", ...) {
  filein <- NULL
  if(is.data.frame(data) == FALSE) {
    stop("data must be in data frame format")
  }
  if(!all(c("e", "c", "t") %in% names(data)) == TRUE) {
    stop("Please rename or provide variables in the data as 'e', 'c' and 't' for the effectiveness, cost and treatment indicator")
  }
  if(any(names(data) == "e") == TRUE & any(names(data) == "c") == TRUE) {
    e <- as.name("e")
    c <- as.name("c")
  }
  if(is.numeric(data$e) == FALSE | is.numeric(data$c) == FALSE) {
    stop("Effectiveness and cost data must be numeric")
  }
  cov_matrix <- subset(data, select = -c(e, c))
  if(any(is.na(cov_matrix)) == TRUE) {
    stop("no missing covariate or treatment indicator is allowed")
  }
  if(!all(levels(as.factor(cov_matrix$t)) %in% c("1", "2")) == TRUE) {
    stop("A two arm indicator variable must be provided with '1' for the control and '2' for the other intervention")
  }
  if(is.character(type) == FALSE | is.character(dist_e) == FALSE | is.character(dist_c) == FALSE) {
    stop("you must provide character names for the objects 'type', 'dist_e' and 'dist_c'")
  }
  dist_e <- tolower(dist_e)
  dist_c <- tolower(dist_c)
  if(dist_e == "normal") { dist_e <- "norm" }
  if(dist_c == "normal") { dist_c <- "norm" }
  if(dist_c == "lognormal") { dist_c <- "lnorm" }
  if(!dist_e %in% c("norm", "beta") | !dist_c %in% c("norm", "gamma", "lnorm")) {
    stop("Distributions available for use are 'norm' or 'beta' for the effects and 'norm', 'gamma', 'lnorm' for the costs")
  }
  type <- toupper(type)
  if(!type %in% c("SCAR", "SAR")) {
    stop("Types available for use are 'SCAR' and 'SAR'")
  }
  if(length(prob) != 2 | is.numeric(prob) == FALSE | any(prob < 0) != FALSE | any(prob > 1) != FALSE) {
    stop("You must provide valid lower/upper quantiles for the imputed data distribution")
  }
  if(is.logical(save_model) == FALSE) {
    stop("save_model should be either TRUE or FALSE")
  }
  data_read <- data_read_hurdle(data = data, model.eff = model.eff, model.cost = model.cost, 
                                model.se = model.se, model.sc = model.sc, se = se, sc = sc, type = type)
  str_eff_assumption <- model.frame(formula = model.se, data = data_read$data_ind)
  str_cost_assumption <- model.frame(formula = model.sc, data = data_read$data_ind)
  if(length(names(str_eff_assumption)) == 1) {
   type2e <- "SCAR"
  } else if(length(names(str_eff_assumption)) > 1) {
    type2e <- "SAR"
  }
  if(length(names(str_cost_assumption)) == 1) {
    type2c <- "SCAR"
  } else if(length(names(str_cost_assumption)) > 1) {
    type2c <- "SAR"
  }
  if(type == "SCAR") {
  if(type != type2e | type != type2c) {
    stop("Please remove covariates from 'model.se' and/or 'mode.sc' if 'SCAR' type selected")
   }
  } else if(type == "SAR") {
    if(type != type2e & type != type2c) {
      stop("Please add covariates to 'model.se' and/or 'mode.sc' if 'SAR' type selected")
    }
    if(type == type2e & is.null(se) == TRUE) {
      stop("It is not possible to assume mechanism if structural values are not provided")
    }
    if(type == type2c & is.null(sc) == TRUE) {
      stop("It is not possible to assume mechanism if structural values are not provided")
    }
  }
  N1 <- data_read$arm_lengths[1]
  N2 <- data_read$arm_lengths[2]
  pe <- ncol(data_read$covariates_effects$Intervention)
  pc <- ncol(data_read$covariates_costs$Intervention)
  ze <- ncol(data_read$covariates_structural_effects$Intervention)
  zc <- ncol(data_read$covariates_structural_costs$Intervention)
  m_eff1 <- data_read$missing_effects$Control
  m_eff2 <- data_read$missing_effects$Intervention
  m_cost1 <- data_read$missing_costs$Control
  m_cost2 <- data_read$missing_costs$Intervention
  d_eff1 <- data_read$structural_effects$Control
  d_eff2 <- data_read$structural_effects$Intervention
  d_cost1 <- data_read$structural_costs$Control
  d_cost2 <- data_read$structural_costs$Intervention
  eff1 <- data_read$raw_effects$Control
  eff2 <- data_read$raw_effects$Intervention
  cost1 <- data_read$raw_costs$Control
  cost2 <- data_read$raw_costs$Intervention
  if(length(which(is.na(c(eff1, eff2)))) == 0 & length(which(is.na(c(cost1, cost2)))) == 0) {
    stop("At leat one missing value is required in either the effects or costs variables")
  }
  N1_cc <- data_read$arm_lengths_cc[, 1]
  N2_cc <- data_read$arm_lengths_cc[, 2]
  N1_mis <- data_read$arm_missing_data[, 1]
  N2_mis <- data_read$arm_missing_data[, 2]
  X1_e <- as.matrix(data_read$covariates_effects$Control)
  X2_e <- as.matrix(data_read$covariates_effects$Intervention)
  X1_c <- as.matrix(data_read$covariates_costs$Control)
  X2_c <- as.matrix(data_read$covariates_costs$Intervention)
  if(pe == 1) {
    X1_e <- as.vector(X1_e)
    X2_e <- as.vector(X2_e)
  }
  if(pc == 1) {
    X1_c <- as.vector(X1_c)
    X2_c <- as.vector(X2_c)
  }
  mean_cov_e1 <- as.vector(data_read$mean_cov_effects$Control)
  mean_cov_e2 <- as.vector(data_read$mean_cov_effects$Intervention)
  mean_cov_c1 <- as.vector(data_read$mean_cov_costs$Control)
  mean_cov_c2 <- as.vector(data_read$mean_cov_costs$Intervention)
  if(is.null(sc) == TRUE & is.null(se) == FALSE) {
    Z1_e <- as.matrix(data_read$covariates_structural_effects$Control)
    Z2_e <- as.matrix(data_read$covariates_structural_effects$Intervention)
    if(ze == 1) {
      Z1_e <- as.vector(Z1_e)
      Z2_e <- as.vector(Z2_e)
    }
    mean_z_e1 <- as.vector(data_read$mean_cov_structural_effects$Control)
    mean_z_e2 <- as.vector(data_read$mean_cov_structural_effects$Intervention)
  } else if(is.null(sc) == FALSE & is.null(se) == TRUE) {
    Z1_c <- as.matrix(data_read$covariates_structural_costs$Control)
    Z2_c <- as.matrix(data_read$covariates_structural_costs$Intervention)
    if(zc == 1) {
      Z1_c <- as.vector(Z1_c)
      Z2_c <- as.vector(Z2_c)
    }
    mean_z_c1 <- as.vector(data_read$mean_cov_structural_costs$Control)
    mean_z_c2 <- as.vector(data_read$mean_cov_structural_costs$Intervention)
  } else if(is.null(sc) == FALSE & is.null(se) == FALSE) {
    Z1_e <- as.matrix(data_read$covariates_structural_effects$Control)
    Z2_e <- as.matrix(data_read$covariates_structural_effects$Intervention)
    if(ze == 1) {
      Z1_e <- as.vector(Z1_e)
      Z2_e <- as.vector(Z2_e)
    }
    mean_z_e1 <- as.vector(data_read$mean_cov_structural_effects$Control)
    mean_z_e2 <- as.vector(data_read$mean_cov_structural_effects$Intervention)
    Z1_c <- as.matrix(data_read$covariates_structural_costs$Control)
    Z2_c <- as.matrix(data_read$covariates_structural_costs$Intervention)
    if(zc == 1) {
      Z1_c <- as.vector(Z1_c)
      Z2_c <- as.vector(Z2_c)
    }
    mean_z_c1 <- as.vector(data_read$mean_cov_structural_costs$Control)
    mean_z_c2 <- as.vector(data_read$mean_cov_structural_costs$Intervention)
  }
  corr_assumption <- model.frame(formula = model.cost, data = data)
  if("e" %in% names(corr_assumption)) {
    ind = FALSE  
  } else{ind = TRUE }
  exArgs <- list(...)
  if(anyDuplicated(names(prior)) > 0) {
    stop("you cannot provide multiple priors with the same name") 
  }
  if(any(prior == "default") == TRUE) {
    prior <- list(default = "default")
    } else if(any(prior == "default") == FALSE) {
    list_check_vector <- lapply(prior, is.vector)
    if(all(as.logical(list_check_vector)) == FALSE) {
      stop("all user-supplied priors should be in vector format")
    }
    par_prior <- c("alpha0.prior", "beta0.prior", "sigma.prior.e", "sigma.prior.c", "gamma.prior.e", "gamma.prior.c", 
                   "alpha.prior", "beta.prior", "gamma0.prior.e", "gamma0.prior.c", "se.prior", "sc.prior", "beta_f.prior")
    stop_mes <- "priors can be assigned only using specific string parameter names depending on the type of model assumed. Type ''help(hurdle)'' for more details"
    if(!all(names(list_check_vector) %in% par_prior == TRUE)) {stop(stop_mes) }
    if(is.vector(X1_e) == TRUE & identical(X1_e,rep(1,N1))) {
      if("alpha.prior" %in% names(list_check_vector)) {stop(stop_mes) }
    }
    if(is.vector(X1_c) == TRUE & identical(X1_c,rep(1,N1))) {
      if("beta.prior" %in% names(list_check_vector)) {stop(stop_mes) }
    }
    if(length(names(str_eff_assumption)) == 1) {
      if("gamma.prior.e" %in% names(list_check_vector)) {stop(stop_mes) }
    }
    if(length(names(str_cost_assumption)) == 1) {
      if("gamma.prior.c" %in% names(list_check_vector)) {stop(stop_mes) }
    }
    if(is.null(se) == TRUE) {
      if("se.prior" %in% names(list_check_vector)) {stop(stop_mes) }
    } else if(is.null(sc) == TRUE) {
      if("sc.prior" %in% names(list_check_vector)) {stop(stop_mes) }
    }
    if(ind == TRUE) {
      if("beta_f.prior" %in% names(list_check_vector)) {stop(stop_mes) } 
    }
  }
  if(exists("sigma.prior.e", where = prior)) {sigma.prior.e = prior$sigma.prior.e} else {sigma.prior.e = NULL }
  if(exists("sigma.prior.c", where = prior)) {sigma.prior.c = prior$sigma.prior.c} else {sigma.prior.c = NULL }
  if(exists("alpha0.prior", where = prior)) {alpha0.prior = prior$alpha0.prior} else {alpha0.prior = NULL }
  if(exists("beta0.prior", where = prior)) {beta0.prior = prior$beta0.prior} else {beta0.prior = NULL }
  if(exists("alpha.prior", where = prior)) {alpha.prior = prior$alpha.prior} else {alpha.prior = NULL }
  if(exists("beta.prior", where = prior)) {beta.prior = prior$beta.prior} else {beta.prior = NULL }
  if(exists("gamma.prior.e", where = prior)) {gamma.prior.e = prior$gamma.prior.e} else {gamma.prior.e = NULL }
  if(exists("gamma.prior.c", where = prior)) {gamma.prior.c = prior$gamma.prior.c} else {gamma.prior.c = NULL }
  if(exists("gamma0.prior.e", where = prior)) {gamma0.prior.e = prior$gamma0.prior.e} else {gamma0.prior.e = NULL }
  if(exists("gamma0.prior.c", where = prior)) {gamma0.prior.c = prior$gamma0.prior.c} else {gamma0.prior.c = NULL }
  if(exists("se.prior", where = prior)) {se.prior = prior$se.prior} else {se.prior = 0.0000001 }
  if(exists("sc.prior", where = prior)) {sc.prior = prior$sc.prior} else {sc.prior = 0.0000001 }
  if(exists("beta_f.prior", where = prior)) {beta_f.prior = prior$beta_f.prior} else {beta_f.prior = NULL }
  sde <- se.prior
  sdc <- sc.prior
  if(length(sde) != 1 | length(sdc) != 1) {stop("single value priors on std for structural values must be provided") }
  if(exists("d_e", where = exArgs)) {d_e = as.vector(exArgs$d_e) } else {d_e = NULL }
  if(is.null(d_e) == FALSE) {
    if(length(d_e) != length(data$e)) {stop("please provide valid structural value indicator vector") }
    d_eff1 = d_e[data$t == 1]
    d_eff2 = d_e[data$t == 2]
    if(is.null(se) == TRUE) {stop("no structural value provided") }
    data_read$structural_effects[[1]] <- d_eff1
    data_read$structural_effects[[2]] <- d_eff2
  }
  if(exists("d_c", where = exArgs)) {d_c = as.vector(exArgs$d_c) } else {d_c = NULL }
  if(is.null(d_c) == FALSE) {
    if(length(d_c) != length(data$c)) {stop("please provide valid structural value indicator vector") }
    d_cost1 = d_c[data$t == 1]
    d_cost2 = d_c[data$t == 2]
    if(is.null(sc) == TRUE) {stop("no structural value provided") }
    data_read$structural_costs[[1]] <- d_cost1
    data_read$structural_costs[[2]] <- d_cost2
  }
    if(is.null(sc) == TRUE & is.null(se) == FALSE) {
      data_set <- list("effects" = data_read$raw_effects, "costs" = data_read$raw_costs, "N in reference arm" = N1, "N in comparator arm" = N2, 
                       "N observed in reference arm" = N1_cc, "N observed in comparator arm" = N2_cc, "N missing in reference arm" = N1_mis, "N missing in comparator arm" = N2_mis, 
                       "covariates_effects" = data_read$covariates_effects, "covariates_costs" = data_read$covariates_costs, 
                       "covariates_structural_effects" = data_read$covariates_structural_effects, "structural_effects" = data_read$structural_effects)
    } else if(is.null(sc) == FALSE & is.null(se) == TRUE) {
      data_set <- list("effects" = data_read$raw_effects, "costs" = data_read$raw_costs, "N in reference arm" = N1, "N in comparator arm" = N2, 
                       "N observed in reference arm" = N1_cc, "N observed in comparator arm" = N2_cc, "N missing in reference arm" = N1_mis, "N missing in comparator arm" = N2_mis, 
                       "covariates_effects" = data_read$covariates_effects, "covariates_costs" = data_read$covariates_costs, 
                       "covariates_structural_costs" = data_read$covariates_structural_costs, "structural_costs" = data_read$structural_costs)
    } else if(is.null(sc) == FALSE & is.null(se) == FALSE) {
      data_set <- list("effects" = data_read$raw_effects, "costs" = data_read$raw_costs, "N in reference arm" = N1, "N in comparator arm" = N2, 
                       "N observed in reference arm" = N1_cc, "N observed in comparator arm" = N2_cc, "N missing in reference arm" = N1_mis, "N missing in comparator arm" = N2_mis, 
                       "covariates_effects" = data_read$covariates_effects, "covariates_costs" = data_read$covariates_costs, 
                       "covariates_structural_effects" = data_read$covariates_structural_effects, "covariates_structural_costs" = data_read$covariates_structural_costs, 
                       "structural_effects" = data_read$structural_effects, "structural_costs" = data_read$structural_costs)
    }
  model_output <- run_hurdle(type = type, dist_e = dist_e, dist_c = dist_c, inits = inits, se = se, sc = sc, sde = sde, sdc = sdc)
  if(save_model == FALSE) {
    unlink(filein)
  }
    if(exists("ref", where = exArgs)) {ref = exArgs$ref } else {ref = 2 }
    if(exists("interventions", where = exArgs)) {interventions = exArgs$interventions } else {interventions = NULL }
    if(exists("Kmax", where = exArgs)) {Kmax = exArgs$Kmax } else {Kmax = 50000 }
    if(exists("wtp", where = exArgs)) {wtp = exArgs$wtp } else {wtp = NULL }
    if(exists("plot", where = exArgs)) {plot = exArgs$plot } else {plot = FALSE }
    cea <- BCEA::bcea(e = model_output$mean_effects, c = model_output$mean_costs, ref = ref, interventions = interventions, Kmax = Kmax, wtp = wtp, plot = plot)
    res <- list(data_set = data_set, model_output = model_output, cea = cea, type = type)
  class(res) <- "missingHE"
  return(res)
}
