unit MongoTestConsts;

interface

const
  DATE_TIME_EPSILON = 1000; // we ignore value less then 1 sec cause unix timestamp
  // is second-aligned value and mongodb just cut miliseconds

implementation

end.

