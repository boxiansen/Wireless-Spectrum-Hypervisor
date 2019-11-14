import select
import socket
import time
import _thread
import threading
import getopt
import queue
import random
from time import sleep
import signal, os

import sys
sys.path.append('../../')
sys.path.append('../../communicator/python/')

from communicator.python.Communicator import Message
from communicator.python.LayerCommunicator import LayerCommunicator
import communicator.python.interf_pb2 as interf

# ********************************* Definitions *********************************
# Number of bits (TB) that can be transmitted in one suframe, i.e., 1 ms. These number are for a bandwidth of 5 MHz, i.e., 25 RBs.
NUM_BYTES_PER_SUBFRAME_VS_MCS_1MHz4 = [19,26,32,41,51,63,75,89,101,117,117,129,149,169,193,217,225,225,241,269,293,325,349,373,405,437,453,469,549]
NUM_BYTES_PER_SUBFRAME_VS_MCS_3MHz = [49,65,81,109,133,165,193,225,261,293,293,333,373,421,485,533,573,573,621,669,749,807,871,935,999,1063,1143,1191,1383]
NUM_BYTES_PER_SUBFRAME_VS_MCS_5MHz = [85,113,137,177,225,277,325,389,437,501,501,549,621,717,807,903,967,967,999,1143,1239,1335,1431,1572,1692,1764,1908,1980,2292]
NUM_BYTES_PER_SUBFRAME_VS_MCS_10MHz = [173,225,277,357,453,549,645,775,871,999,999,1095,1239,1431,1620,1764,1908,1908,2052,2292,2481,2673,2865,3182,3422,3542,3822,3963,4587]
NUM_BYTES_PER_SUBFRAME_VS_MCS_15MHz = [261,341,421,549,669,839,967,1143,1335,1479,1479,1620,1908,2124,2385,2673,2865,2865,3062,3422,3662,4107,4395,4736,5072,5477,5669,5861,6882]
NUM_BYTES_PER_SUBFRAME_VS_MCS_20MHz = [349,453,573,717,903,1095,1287,1527,1764,1980,1980,2196,2481,2865,3182,3542,3822,3822,4107,4587,4904,5477,5861,6378,6882,7167,7708,7972,9422]

# PHY Results.
PHY_UNKNOWN             = 0
PHY_SUCCESS             = 100
PHY_ERROR               = 101
PHY_TIMEOUT             = 102

# Physical Layer States.
PHY_UNKNOWN_ST          = 0
TRX_RX_ST               = 1
TRX_TX_ST               = 2

# BW Indexes.
BW_UNKNOWN              = 0 # unknown
BW_IDX_OneDotFour	    = 1	# 1.4 MHz
BW_IDX_Three	   		= 2	# 3 MHz
BW_IDX_Five	   		    = 3	# 5 MHz
BW_IDX_Ten		   		= 4	# 10 MHz
BW_IDX_Fifteen          = 5 # 15 MHz
BW_IDX_Twenty           = 6 # 20 MHz

# ************ Functions ************
tx_exit_flag = False
def handler(signum, frame):
    global tx_exit_flag
    tx_exit_flag = True

def getExitFlag():
    global tx_exit_flag
    return tx_exit_flag

tx_stat_flag_lock = threading.Lock()
is_tx_stat_received = False
def get_is_stat_received():
    tx_stat_flag_lock.acquire()
    global is_tx_stat_received
    flag = is_tx_stat_received
    tx_stat_flag_lock.release()
    return flag

def set_is_stat_received(flag):
    tx_stat_flag_lock.acquire()
    global is_tx_stat_received
    is_tx_stat_received = flag
    tx_stat_flag_lock.release()

txStatthreadLock = threading.Lock()
tx_sequence_number = 0
def set_seq_number(seq_num):
    # Get lock to synchronize threads
    txStatthreadLock.acquire()
    global tx_sequence_number
    tx_sequence_number = seq_num
    # Free lock to release next thread
    txStatthreadLock.release()

def get_seq_number():
    # Get lock to synchronize threads
    txStatthreadLock.acquire()
    global tx_sequence_number
    seq_num = tx_sequence_number
    # Free lock to release next thread
    txStatthreadLock.release()
    return seq_num

def help():
    print("Usage: pyhton3 continuous_transmissionv2.py")

def printPhyTxStat(internal):
    print("************************ TX PHY Stats Packet ************************")
    print("seq_number: ",internal.transaction_index)
    print("status: ",internal.sendr.result)
    print("host_timestamp: ",internal.sendr.phy_stat.host_timestamp)
    print("fpga_timestamp: ",internal.sendr.phy_stat.fpga_timestamp)
    print("frame: ",internal.sendr.phy_stat.frame)
    print("slot: ",internal.sendr.phy_stat.slot)
    print("ch: ",internal.sendr.phy_stat.ch)
    print("mcs: ",internal.sendr.phy_stat.mcs)
    print("num_cb_total: ",internal.sendr.phy_stat.num_cb_total)
    print("num_cb_err: ",internal.sendr.phy_stat.num_cb_err)
    print("power: ",internal.sendr.phy_stat.tx_stat.power)
    print("*********************************************************************\n")

def printBasicControl(basic_control, seq_number, tx_data):
    print("******************** Basic Control CMD Transmitted ******************")
    print("trx_flag: ",basic_control.trx_flag)
    print("seq_number: ",seq_number)
    print("bw_index: ",basic_control.bw_index)
    print("ch: ",basic_control.ch)
    print("slot: ",basic_control.slot)
    print("mcs: ",basic_control.mcs)
    print("gain: ",basic_control.gain)
    print("length: ",basic_control.length)
    if(basic_control.trx_flag == 1):
        data = []
        for d in tx_data:
            data.append(int(d))
        print("data: ",data)
    print("*********************************************************************\n")

def inputOptions(argv):
    debug = False # by default debug is enabled.
    profiling = False # by default profiling is disabled.
    single = False # By default we use two computers to run the tests.
    wait_for_tx_stats = False

    try:
        opts, args = getopt.getopt(argv,"hdpst",["help","debug","profile","single","txstats"])
    except getopt.GetoptError:
        help()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            help()
            sys.exit()
        elif opt in ("-d", "--debug"):
            debug = True
        elif opt in ("-p", "--profile"):
            profiling = True
        elif opt in ("-s", "--single"):
            single = True
        elif opt in ("-t", "--txstats"):
            wait_for_tx_stats = True

    return debug, profiling, single, wait_for_tx_stats

def sendRxCtrlToPhy(lc, chan, mcs_idx, rx_gain, num_data_slots, seq_number, module, debug):

    # Basic Control
    trx_flag    = TRX_RX_ST    # TRX Mode. 1 TX - 0 RX;
    send_to     = 0                 # Radio ID to send slot to.
    seq_number  = seq_number        # Sequence number.
    bw_idx      = BW_IDX_Five       # By default use BW: 5 MHz. Possible values: 0 - 1.4 MHz, 1 - 3 MHz, 2 - 5 MHz, 3 - 10 MHz.
    mcs         = mcs_idx           # It has no meaning for RX. MCS is recognized automatically by receiver. MCS varies from 0 to 28.
    channel     = chan              # By default use channel 0.
    slot        = 0                 # Slot number (not used now, for future use)
    frame       = 0
    gain        = rx_gain           # RX gain. We use -1 for AGC mode.
    num_slots   = num_data_slots    # Number of slots. How many data slots we expect to receive from peer.

    # Create an Internal message for RX procedure.
    internal = interf.Internal()
    # Add sequence number to internal message.
    internal.transaction_index = seq_number

    # Add values to the Basic Control Message for RX procedure.
    internal.receive.basic_ctrl.trx_flag     = trx_flag
    internal.receive.basic_ctrl.send_to      = send_to
    internal.receive.basic_ctrl.bw_index     = bw_idx
    internal.receive.basic_ctrl.ch           = channel
    internal.receive.basic_ctrl.frame        = frame
    internal.receive.basic_ctrl.slot         = slot
    internal.receive.basic_ctrl.mcs          = mcs
    internal.receive.basic_ctrl.gain         = gain
    internal.receive.basic_ctrl.length       = num_slots

    # Print the basic control structure sent to PHY.
    if(debug == True): printBasicControl(internal.receive.basic_ctrl, internal.transaction_index)

    # Send basic control to PHY.
    if(debug == True): print("Sending basic control to PHY.")
    lc.send(Message(module, interf.MODULE_PHY, internal))

def sendTxCtrlToPhy(lc, channel, bandwidth, mcs, gain_value, num_slots, sequence_number, timestamp, module, data, debug):
    # Create an Internal message for TX procedure.
    internal = interf.Internal()
    # Add sequence number to internal message.
    internal.transaction_index = sequence_number
    # Set basic control with proper values.
    internal.send.basic_ctrl.trx_flag     = TRX_TX_ST
    internal.send.basic_ctrl.send_to      = 0
    internal.send.basic_ctrl.bw_index     = bandwidth
    internal.send.basic_ctrl.ch           = channel
    internal.send.basic_ctrl.frame        = 0
    internal.send.basic_ctrl.slot         = 0
    internal.send.basic_ctrl.timestamp    = timestamp
    internal.send.basic_ctrl.mcs          = mcs
    internal.send.basic_ctrl.gain         = gain_value
    internal.send.basic_ctrl.length       = num_slots*getTransportBlockSize(bandwidth, mcs)
    internal.send.app_data.data           = data

    lc.send(Message(module, interf.MODULE_PHY, internal))

def generateRandomData(num_slots, bw_idx, mcs):
    random_data = bytes()
    for j in range(num_slots):
        for i in range(getTransportBlockSize(bw_idx, mcs)):
            random_data = random_data + bytes([random.randint(0, 255)])

    return random_data

def generateData(num_slots, seq_number, bw_idx, mcs):
    data = bytes()
    for j in range(num_slots):
        for i in range(getTransportBlockSize(bw_idx, mcs)):
            data = data + bytes([seq_number])
    return data

def generateData2(num_slots, seq_number, bw_idx, mcs):
    data = bytes()
    for j in range(num_slots):
        for i in range(getTransportBlockSize(bw_idx, mcs)):
            data = data + bytes([seq_number+j])
    return data

def getTransportBlockSize(index, mcs):
    if index == BW_IDX_OneDotFour:
        tb_size = NUM_BYTES_PER_SUBFRAME_VS_MCS_1MHz4[mcs]
    elif index == BW_IDX_Three:
        tb_size = NUM_BYTES_PER_SUBFRAME_VS_MCS_3MHz[mcs]
    elif index == BW_IDX_Five:
        tb_size = NUM_BYTES_PER_SUBFRAME_VS_MCS_5MHz[mcs]
    elif index == BW_IDX_Ten:
        tb_size = NUM_BYTES_PER_SUBFRAME_VS_MCS_10MHz[mcs]
    elif index == BW_IDX_Fifteen:
        tb_size = NUM_BYTES_PER_SUBFRAME_VS_MCS_15MHz[mcs]
    elif index == BW_IDX_Twenty:
        tb_size = NUM_BYTES_PER_SUBFRAME_VS_MCS_20MHz[mcs]
    else:
        tb_size = -1;

    return tb_size

def receiveStatisticsFromPhyThread(lc, stats_queue, num_of_tx_slots, wait_for_tx_stats, debug):
    expected_rxd_byte = -1 # last received byte
    last_rxd_byte = -1
    out_of_seq_cnt = 0 # out of sequence error counter.
    in_seq_cnt = 0 # In sequence counter.
    total_pkt_number = 0 # Total number of received packets.
    correct_tx_slot_counter = 0
    same_packet_cnt = 0

    while(getExitFlag() == False):
        # Check if QUEUE is empty.
        if(lc.get_low_queue().empty() == False):
            try:
                #Try to get next message without waiting.
                msg = lc.get_low_queue().get_nowait()
                internal = msg.message
                if(wait_for_tx_stats == True and internal.sendr.result > 0 and internal.sendr.result == PHY_SUCCESS):
                    if(internal.transaction_index >= 100 and internal.transaction_index < 200 and get_seq_number() == internal.transaction_index):
                        stats_queue.put(internal)
                        set_is_stat_received(True)
                    else:
                        print("Sequence number out of sequence, expecting:", get_seq_number(), "and received: ", internal.transaction_index, "exiting.")
                        os._exit(-1)
                elif(internal.receiver.result > 0 and internal.receiver.result == PHY_SUCCESS):
                    if(internal.transaction_index == 66):
                       # Get PHY RX Statistics from PHY.
                       total_rxd_bytes = internal.receiver.data
                       host_timestamp = internal.receiver.stat.host_timestamp

                       if(len(total_rxd_bytes) > 0):
                           total_pkt_number = total_pkt_number + 1 # Increment the number of received packets.

                           if(expected_rxd_byte == -1):
                               expected_rxd_byte = total_rxd_bytes[0]

                           if(total_rxd_bytes[0] == expected_rxd_byte):
                               if(debug == True): print("Received:",total_rxd_bytes[0]," - Expected:",expected_rxd_byte)
                               in_seq_cnt = in_seq_cnt + 1
                           else:
                               print("--------> Out of Seq:", out_of_seq_cnt,"- In Seq:", in_seq_cnt, "- Total # pkts:", total_pkt_number, "- % lost packets:", ((out_of_seq_cnt*100)/total_pkt_number),  " - Received:", total_rxd_bytes[0], " - Expected:", expected_rxd_byte, "- Host timestamp:",host_timestamp)
                               out_of_seq_cnt = out_of_seq_cnt + 1

                           if(last_rxd_byte != total_rxd_bytes[0]):
                               if(total_rxd_bytes[0] == 100):
                                   expected_rxd_byte = 0
                               else:
                                   expected_rxd_byte = total_rxd_bytes[0]
                               expected_rxd_byte = (expected_rxd_byte + 1)

                           # Store the last received byte.
                           last_rxd_byte = total_rxd_bytes[0]
                    else:
                        print("Sequence number out of sequence, expecting:", get_seq_number(), "and received: ", internal.transaction_index, "exiting.")
                        os._exit(-1)
            except queue.Empty:
                print("QUEUE is empty.");
        # Check is exit flag is set.
        if(getExitFlag() == True):
            print("Exit receiving function.")
            break

if __name__ == '__main__':

    # Parse any input option.
    debug, profiling, single, wait_for_tx_stats = inputOptions(sys.argv[1:])

    # Set the signal handler.
    signal.signal(signal.SIGINT, handler)

    # decides if single or two host PCs.
    if(single == False):
        source_module = interf.MODULE_MAC # Make believe it is the MAC layer sending controls to PHY.
    else:
        source_module = interf.MODULE_DEBUG2

    print("Create CommManager object.")
    lc = LayerCommunicator(source_module, [interf.MODULE_PHY])

    # Create a QUEUE to store data.
    # Create a single input and a single output queue for all threads.
    stats_queue = queue.Queue()

    channel = 0
    bandwidth = BW_IDX_Five
    mcs = 0
    tx_gain = 10 # Good value for b200: 30 # for x310 use 200
    rx_gain = 10
    num_of_tx_slots = 1
    num_of_rx_slots = 1
    seq_number = 100
    num_of_tx = -1
    data = generateRandomData(num_of_tx_slots, bandwidth, mcs)
    packet_counter = 0

    # Start TX statistics thread.
    # Wait for PHY TX Statistics from PHY.
    try:
        thread_id = _thread.start_new_thread( receiveStatisticsFromPhyThread, (lc, stats_queue, num_of_tx_slots, wait_for_tx_stats, debug, ) )
    except:
        print("Error: unable to start thread")
        sys.exit(-1)

    # Give the thread some time.
    time.sleep(2)

    # Send RX control information to PHY.
    sendRxCtrlToPhy(lc, channel, mcs, rx_gain, num_of_rx_slots, 66, source_module, debug)

    while(getExitFlag() == False and packet_counter != num_of_tx):
        # Count the number of transmitted slots.
        packet_counter = packet_counter + 1

        # Send sequence number to TX stats thread.
        set_seq_number(seq_number)

        # Generate data according to sequence number.
        data = generateData2(num_of_tx_slots, seq_number-99, bandwidth, mcs)

        # Send TX control information to PHY.
        timestamp = int(time.time()*1000) + 150;
        sendTxCtrlToPhy(lc, channel, bandwidth, mcs, tx_gain, num_of_tx_slots, seq_number, timestamp, source_module, data, debug)

        # Increment sequence number.
        seq_number = (seq_number + num_of_tx_slots)%200
        if(seq_number == 0):
            seq_number = 100;

        # Wait sometime before transmitting again.
        time.sleep(0.005)
