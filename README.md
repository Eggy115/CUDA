# CUDA

## About

CUDA is a parallel computing platform and programming model developed by NVIDIA that allows developers to harness the power of GPUs for general-purpose computing tasks. The CUDA software stack includes a compiler, runtime libraries, development tools, and a programming API that enables developers to write high-performance parallel code in a familiar language such as C, C++, or Python. NVIDIA maintains an open-source GitHub repository for CUDA, providing developers with access to the latest CUDA releases, sample code, and documentation. In this repository, developers can collaborate, share their code, report issues, and contribute to the ongoing development of CUDA.

## Installation

- Check system requirements: Ensure that your system meets the minimum hardware and software requirements for CUDA. This includes having a compatible NVIDIA GPU and a supported operating system.
- Download CUDA Toolkit: Go to the NVIDIA CUDA website and download the latest version of the CUDA Toolkit for your operating system. Choose the appropriate version based on your system architecture and operating system version.
- Run installer: Run the downloaded installer and follow the prompts to install the CUDA Toolkit. During the installation process, you may need to select options such as the installation directory and whether to install additional components such as the CUDA samples.
- Configure environment variables: After the installation is complete, you may need to configure environment variables such as PATH and LD_LIBRARY_PATH to include the CUDA binaries and libraries.
- Verify installation: Verify that CUDA is installed and working correctly by running the deviceQuery sample code included with the CUDA Toolkit. This program will display information about the installed GPUs and their capabilities.
- Clone repository

```
git clone https://github.com/Eggy115/CUDA.git
```

## Contributing

If you would like to contribute to this repository, please fork it on GitHub and submit a pull request with your changes. We welcome contributions that fix bugs, add new features, improve documentation, or optimize performance.

## License

These CUDA scripts are released under the GPL license. See the [LICENSE](./LICENSE) file for details.
