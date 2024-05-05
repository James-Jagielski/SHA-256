# Simple tests for an counter module
import binascii
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge
from random import randrange
from Utils.helper import preprocessMessage
if cocotb.simulator.is_running():
    from SHA_256 import sha_256_accelerator


tests = ["",
"abc",
"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
"abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu",
"a" * 1000000,
"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopqp", #edge-case: between 448 and 512 bits long message (456)
"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopqpqpmomom", #edge-case: 512 bits
"ibsnqwpzhillptcinmtvamymvixjxaumjddwxsxxjhjhnftynajhsluuctgjytazlcdewsexbjcpumdcfbbbmzwxcmjmnxfqurvaarapdswyatlyvqsxdefmehicwwdnkshzgysaxxenmtpirbhphxyaesgwigdxzqpekouenexqkqgpnzzwyjppc",
"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
"248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",
"cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1",
"cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0",
"3234a5b08b1112a6cb90bf9920ca1863535c9380a65633e5442befda64f84a6f", #hashlib result
"19c638400f16d98b8d955a0bfe853cb11c33a987389ac2311b9c0ba2cd1efa34", #hashlib result
"6540979c2b56a3f4b17dada9a3d1fba7161d0e10f2c2d87b0b6486377bf88ecc"]


@cocotb.test()
async def SHA_256(dut):
    # generate a clock
    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    for j in range(2):
        # initalize
        test_str = tests[j]
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

        message = sha_256_accelerator("GJamesKenta")

        await Timer(114, units="ns")

        dut._log.info("Final state is %s", dut.hash_state.value)
        dut._log.info("Input flag is %s", dut.input_valid.value)
        dut._log.info("Output flag is %s", dut.output_valid.value)
        hash = str(dut.output_hash.value)[12:268]
        test = format(int(message,16),'b')

        print("HASH", hash)
        print("TEST", test)

        assert test == hash, f"The hashes are equal python:{test} verilog:{hash}"
        
