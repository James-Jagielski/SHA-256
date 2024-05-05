# SHA-256

This is an implementation of a SHA-256 hashing algorithm. We implement the compression function on it's own hardware and the CPU handles the message manipulation for padding and sizing for the input into the algorithm.

For testing we used cocotb software to unit test edge cases. Through these simulations we were successfully passes all our unit tests. The python module we are using is taken from the github repository: [repo](https://github.com/pdoms/SHA256-PYTHON) and [blog about the python code](https://medium.com/@domspaulo/python-implementation-of-sha-256-from-scratch-924f660c5d57). 

During our implementation of the SHA-256 we found these websites to be useful for understanding the algorithm: [Step by step walk through](https://www.educative.io/answers/what-are-the-different-steps-in-sha-256) and [Pseudocode section](https://en.wikipedia.org/wiki/SHA-2).