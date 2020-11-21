#include "Vmsgpu.h"
#include "verilated.h"

#include <memory>

#include <gtest/gtest.h>

class MsgpuShould : public ::testing::Test
{
public:
    MsgpuShould() : sut_(new Vmsgpu)
    {
    }

protected:
    void tick()
    {
        sut_->clock = 0;
        sut_->eval();
        sut_->mcu_bus = bus_state_;
        sut_->clock = 1;
        sut_->eval();
    }

    void delay(int ticks)
    {
        for (int i = 0; i < ticks; ++i)
        {
            tick();
        }
    }

    void generate_sclk()
    {
        sut_->mcu_bus_clock = 1;
        tick();
        tick();
        tick();
        sut_->mcu_bus_clock = 0;
        tick();
        tick();
        tick();
    }

    void send_byte(uint8_t byte)
    {
        bus_state_ = byte;
        sut_->mcu_bus_command_data = 1;
        generate_sclk();
    }

    void send(uint32_t data)
    {
        send_byte(static_cast<uint8_t>(data >> 24));
        send_byte(static_cast<uint8_t>(data >> 16));
        send_byte(static_cast<uint8_t>(data >> 8));
        send_byte(static_cast<uint8_t>(data));
    }

    void send_command(uint8_t command)
    {
        bus_state_ = command;
        sut_->mcu_bus_command_data = 0;
        generate_sclk();
    }

    void set_address(uint32_t address)
    {
        constexpr uint8_t set_address_command = 0x02;
        send_command(set_address_command);
        send(address);
    }

    uint8_t bus_state_;
    std::unique_ptr<Vmsgpu> sut_;
};

TEST_F(MsgpuShould, WriteDataToPsram)
{
    tick();
    set_address(0xdeadbeef);
}
