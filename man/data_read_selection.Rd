% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data_read_selection.R
\name{data_read_selection}
\alias{data_read_selection}
\title{A function to read and re-arrange the data in different ways}
\usage{
data_read_selection(data, model.eff, model.cost, model.me, model.mc,
  type = type)
}
\arguments{
\item{data}{A data frame in which to find variables supplied in \code{model.eff} and \code{model.cost}. Among these,
effectiveness, cost and treatment indicator (only two arms) variables must always be provided and named 'e', 'c' and 't' respectively.}

\item{model.eff}{A formula expression in conventional \code{R} linear modelling syntax. The response must be a health economics
effectiveness outcome ('e') whose name must correspond to that used in \code{data}, and 
any covariates are given on the right-hand side. If there are no covariates, specify \code{1} on the right hand side.
By default, covariates are placed on the "location" parameter of the distribution through a linear model.}

\item{model.cost}{A formula expression in conventional \code{R} linear modelling syntax. The response must be a health economics
cost outcome ('c') whose name must correspond to that used in \code{data}, and any covariates are given on the right-hand side.
If there are no covariates, specify \code{1} on the right hand side. By default, covariates are placed on the "location" 
parameter of the distribution through a linear model.}

\item{model.me}{A formula expression in conventional \code{R} linear modelling syntax.  The response must be indicated with the 
term 'me'(missing effects) and any covariates used to estimate the probability of missing effects are given on the right-hand side. 
If there are no covariates, specify \code{1} on the right hand side. By default, covariates are placed on the "probability" parameter for the missing effects through a logistic-linear model.}

\item{model.mc}{A formula expression in conventional R linear modelling syntax. The response must be indicated with the 
term 'mc'(missing costs) and any covariates used to estimate the probability of missing costs should be given on the right-hand side. 
If there are no covariates, specify \code{1} on the right hand side. By default, covariates are placed on the "probability" parameter for the missing costs through a logistic-linear model.}

\item{type}{Type of missingness mechanism assumed. Choices are Missing At Random (MAR) and Missing Not At Random (MNAR).}
}
\description{
This internal function imports the data and outputs only those variables that are needed to run the model
according to the information provided by the user.
}
\examples{
\dontrun{
#create a data set which respects the requirements specified in "data" (see Arguments)
N1 <- 150
N2 <- 100
m_eff1 <- m_cost1 <- rbinom(N1, 1, 0.25)
m_eff2 <- m_cost2 <- rbinom(N2, 1, 0.25)
m_cost1 <- m_cost1 <- rbinom(N1, 1, 0.25)
m_cost2 <- m_cost2 <- rbinom(N2, 1, 0.25)
eff1 <- rnorm(N1, 0.5, 0.5)
eff2 <- rnorm(N2, 0.5, 0.5)
cost1 <- rnorm(N1, 90, 20)
cost2 <- rnorm(N2, 90, 20)

#introduce missingness
eff1[m_eff1 == 1] <- NA
eff2[m_eff2 == 1] <- NA
cost1[m_cost1 == 1] <- NA
cost2[m_cost2 == 1] <- NA

#arrange data frame
e <- c(eff1, eff2)
c <- c(cost1, cost2)
m_eff <- c(m_eff1, m_eff2)
m_cost <- c(m_cost1, m_cost2)
t <- c(t1, t2)
data <- data.frame(e ,c, t)

#run the function
date_rearranged <- data_read_selection(data = data, model.eff = e ~ 1, model.cost = c ~ 1
model.me = me ~ 1, model.mc = mc ~ 1, type = "MAR")
}
#
#
}
\keyword{data}
\keyword{read}
