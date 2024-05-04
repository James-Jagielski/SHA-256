# Simple tests for an counter module
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge
from random import randrange
if cocotb.simulator.is_running():
    from SHA_256 import sha_256_accelerator

@cocotb.test()
async def SHA_256(dut):
    # generate a clock
    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())

    # initalize
    test_str = "GeeksforGeeks"
    unpadded = ''.join(format(ord(x), 'b') for x in test_str)
    dut.input_data.value = 2*511
    dut.input_valid.value = 1
    dut.rst.value = 1
    dut.ena.value = 0

    await Timer(3, units="ns")
    # hash variables
    dut.rst.value = 0
    dut.ena.value = 1

    message = sha_256_accelerator(test_str)
    await Timer(10000, units="ns")
    dut._log.info("Final state is %s", dut.hash_state.value)
    dut._log.info("Input flag is %s", dut.input_valid.value)
    dut._log.info("Output flag is %s", dut.output_valid.value)
    hash = dut.output_hash.value
    # run for 50ns checking count on each rising edge
    assert message == hash, f"The hashs are equal python:{message} verilog:{hash}"
        