# Simple tests for an counter module
import binascii
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge
from random import randrange
from Utils.helper import preprocessMessage
if cocotb.simulator.is_running():
    from SHA_256 import sha_256_accelerator

@cocotb.test()
async def SHA_256(dut):
    # generate a clock
    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())

    # initalize
    test_str = "GeeksforGeeks"
    preprocessed = (preprocessMessage(test_str))
    dut.input_data.value = int("".join(str(i) for i in preprocessed[0]), 2)
    dut.input_valid.value = 1
    dut.rst.value = 1
    dut.ena.value = 0

    await Timer(3, units="ns")
    # hash variables
    dut.rst.value = 0
    dut.ena.value = 1

    dut._log.info("INPUT DATA VALUE %s", dut.input_data.value)

    message = sha_256_accelerator("GeeksforGeeks")

    await Timer(10000, units="ns")

    dut._log.info("Final state is %s", dut.hash_state.value)
    dut._log.info("Input flag is %s", dut.input_valid.value)
    dut._log.info("Output flag is %s", dut.output_valid.value)
    hash = str(dut.output_hash.value)[12:268]
    test = format(int(message,16),'b')

    print("HASH", hash)
    print("TEST", test)

    assert test == hash, f"The hashes are equal python:{test} verilog:{hash}"
        