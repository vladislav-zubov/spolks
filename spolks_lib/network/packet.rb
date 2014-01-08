require 'bindata'

module Network
  class Packet < BinData::Record
    endian :little
    uint8 :num_packet
    uint8 :inf_or_data   # 0-data 1-file and pos 3-port
    uint32 :len
    string :data, :read_length => :len
  end
end