% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/write_hurdle.R
\name{write_hurdle}
\alias{write_hurdle}
\title{An internal function to select which type of hurdle model to execute for both effectiveness and costs. 
Alternatives vary depending on the type of distribution assumed for the effect and cost variables,
type of structural value mechanism assumed and independence or joint modelling
This function selects which type of model to execute.}
\usage{
write_hurdle(dist_e, dist_c, ind, type, pe, pc, ze, zc, se, sc)
}
\arguments{
\item{dist_e}{Distribution assumed for the effects. Current available chocies are: Normal ('norm') or Beta ('beta')}

\item{dist_c}{Distribution assumed for the costs. Current available chocies are: Normal ('norm'), Gamma ('gamma') or LogNormal ('lnorm')}

\item{ind}{Logical; if TRUE independence between effectiveness and costs is assumed, else correlation is accounted for}

\item{type}{Type of structural value mechanism assumed. Choices are Structural Completely At Random (SCAR) and Structural At Random (SAR)}

\item{pe}{Number of covariates for the effectiveness model}

\item{pc}{Number of cvoariates for the cost model}

\item{ze}{Number of covariates or the structural indicators model for the effectiveness}

\item{zc}{Number of covariates or the structural indicators model for the costs}

\item{se}{Structural value for the effectiveness}

\item{sc}{Structural value for the costs}
}
\description{
An internal function to select which type of hurdle model to execute for both effectiveness and costs. 
Alternatives vary depending on the type of distribution assumed for the effect and cost variables,
type of structural value mechanism assumed and independence or joint modelling
This function selects which type of model to execute.
}
\examples{
#Internal function only
#No examples
#
#
}
\keyword{Hurdle}
\keyword{JAGS}
\keyword{models}
