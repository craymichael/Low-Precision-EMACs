# Low-Precision-EMACs
RTL design of posit, fixed-point, and floating point low-precision exact-multiply-and-accumulate (EMAC)
units for deep neural networks (DNNs). These designs compute the underlying operation in all DNNs while
preserving as much accuracy locally as possible by incorporating the Kulisch exact-dot-product.

This work was performed while a part of the *Neuromorphic Artificial Intelligence (Nu.AI) Lab* in the
Department of Computer Engineering, Rochester Institute of Technology. If you intend to use this
source, please cite one the following papers below. Note that the source code provided here deviates
from that used in the papers, but exhibits largely the same functionalities. Also, note the license file
in this repository regardless of your potential application.

```
@inproceedings{carmichael2019positron,
  title         = {Deep Positron: {A} Deep Neural Network Using the Posit Number System},
  author        = {Zachariah Carmichael and Hamed Fatemi Langroudi and Char Khazanov and Jeffrey Lillie and John L. Gustafson and Dhireesha Kudithipudi},
  pages         = {1421--1426},
  doi           = {10.23919/DATE.2019.8715262},
  url           = {https://doi.org/10.23919/DATE.2019.8715262},
  crossref      = {DBLP:conf/date/2019}
}

@proceedings{DBLP:conf/date/2019,
  title         = dateconf,
  year          = 2019,
  month         = mar,
  booktitle     = dateconf,
  publisher     = ieee,
  address       = {Florence, Italy},
  isbn          = {978-3-9819263-2-3},
  url           = {http://ieeexplore.ieee.org/xpl/mostRecentIssue.jsp?punumber=8704855},
  eventdate     = {2019-03-25/2019-03-29}
}
```

```
@inproceedings{carmichael2019performance,
  title        = {Performance-Efficiency Trade-off of Low-Precision Numerical Formats in Deep Neural Networks},
  author       = {Carmichael, Zachariah and Langroudi, Hamed F. and Khazanov, Char and Lillie, Jeffrey and Gustafson, John L. and Kudithipudi, Dhireesha},
  year         = 2019,
  booktitle    = {Proceedings of the Conference for Next Generation Arithmetic 2019},
  location     = {Singapore, Singapore},
  publisher    = {ACM},
  address      = {New York, NY, USA},
  series       = {CoNGA'19},
  pages        = {3:1--3:9},
  doi          = {10.1145/3316279.3316282},
  isbn         = {978-1-4503-7139-1},
  url          = {http://doi.acm.org/10.1145/3316279.3316282},
  articleno    = 3,
  numpages     = 9,
  acmid        = 3316282,
}

```

