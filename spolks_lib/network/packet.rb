require 'bindata'

module Network
  class Packet < BinData::Record
    endian :little
    uint8 :num_packet
    uint32 :len
    string :data, :read_length => :len
  end
end