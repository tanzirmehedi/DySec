# DySec
A Machine Learning-based Dynamic Analysis for Detecting Malicious Packages in PyPI Ecosystem

## Overview

Malicious Python packages make software supply chains vulnerable by exploiting trust in open-source repositories like Python Package Index (PyPI). Lack of real-time behavioral monitoring makes metadata inspection and static code analysis inadequate against advanced attack strategies such as typosquatting, covert remote access activation, and dynamic payload generation. To address these challenges, we introduce DySec, a machine learning (ML)-based dynamic analysis framework for PyPI that uses eBPF kernel and user-level probes to monitor behaviors during package installation. By capturing 36 real-time features--including system calls, network traffic, resource usage, directory access, and installation patterns--DySec detects threats like typosquatting, covert remote access activation, dynamic payload generation, and multiphase attack malware. We developed a comprehensive dataset of 14,271 Python packages, including 7,127 malicious sample traces, by executing them in a controlled isolated environment. Experimental results demonstrate that DySec achieves 96% detection accuracy with an ML inference latency of <0.5s after dynamic feature extraction, reducing false negatives by 78.65% compared to static analysis and 82.24% compared to metadata analysis. During the evaluation, DySec flagged eleven packages that PyPI classified as benign. A manual analysis, including installation behavior inspection, confirmed six of them as malicious. These findings were reported to PyPI maintainers, resulting in the removal of four packages. DySec bridges the gap between reactive traditional methods and proactive, scalable threat mitigation in open-source ecosystems by uniquely detecting malicious install-time behaviors.

<p align="center">
  <img src="Figures/Framework.jpg" alt="DySec Framework" width="500"/>
</p>
<p align="center"><em>Figure 1: The overall workflow of DySec for detecting malicious packages.</em></p>

## Citation

If you use this study in your research, please cite it as:

@article{Mehedi2025DySec,
  author    = {Sk Tanzir Mehedi and Chadni Islam and Gowri Ramachandran and Raja Jurdak},
  title     = {DySec: A Machine Learning-based Dynamic Analysis for Detecting Malicious Packages in the PyPI Ecosystem},
  journal   = {arXiv preprint},
  year      = {2025},
  eprint    = {2503.00324},
  archivePrefix = {arXiv},
  primaryClass   = {cs.CR},
  doi       = {10.48550/arXiv.2503.00324},
  url       = {https://arxiv.org/abs/2503.00324}
}

## Authors

- **Sk Tanzir Mehedi** (Queensland University of Technology)  
  [ORCID](https://orcid.org/0000-0003-4435-7856)
- **Chadni Islam** (Edith Cowan University)  
  [ORCID](https://orcid.org/0000-0002-6349-6483)
- **Gowri Ramachandran** (Queensland University of Technology)  
  [ORCID](https://orcid.org/0000-0001-5944-1335)
- **Raja Jurdak** (Queensland University of Technology)  
  [ORCID](https://orcid.org/0000-0001-7517-0782)

## Contact

For questions or collaborations, please contact:

**Sk Tanzir Mehedi**  (s.tanzir@qut.edu.au)

