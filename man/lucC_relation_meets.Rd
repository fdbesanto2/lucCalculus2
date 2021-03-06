% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/lucC_allen_relations.r
\docType{data}
\name{lucC_relation_meets}
\alias{lucC_relation_meets}
\title{Allen Relation Meets}
\usage{
lucC_relation_meets(first_raster = NULL, second_raster = NULL)
}
\arguments{
\item{first_raster}{Matrix. An interval between two dates.}

\item{second_raster}{Matrix. An interval between two dates.}
}
\value{
Data set with merge of two data sets
}
\description{
Provide an Allen's interval relation MEETS which end time interval of the
raster_1 must be (=) equal to the start time interval from raster_2, and also time interval
from raster_1 can not overlap time interval from raster_2. See more at (ALLEN, J. F.
"Maintaining knowledge about temporal intervals". Communications of the ACM, v(26), 11,
1983, 832-843. DOI: \url{http://dx.doi.org/10.1145/182.358434})
}
\examples{
\dontrun{

a <- lucC_pred_holds(raster_obj = rb_sits, raster_class = "Forest",
                     time_interval = c("2001-09-01","2003-09-01"),
                     relation_interval = "equals", label = label,
                     timeline = timeline)
a

b <- lucC_pred_holds(raster_obj = rb_sits, raster_class = "Cerrado",
                     time_interval = c("2004-09-01","2007-09-01"),
                     relation_interval = "equals", label = label,
                     timeline = timeline)
b

# meets
c <- lucC_relation_meets(first_raster = a, second_raster = b)

}

}
\author{
Adeline M. Maciel
}
\keyword{datasets}
