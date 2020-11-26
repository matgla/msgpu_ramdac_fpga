#include "Vmcu_bus.h"
#include "verilated.h"

#include <memory>

#include <gtest/gtest.h>

class MCUBusTests : public ::testing::Test
{
public:
    MCUBusTests() : sut_(new Vmcu_bus)
    {
    }

protected:
    void tick()
    {
        sut_->sysclk = 0;
        sut_->eval();
        sut_->sysclk = 1;
        sut_->eval();
    }

    void raise_sclk()
    {
        sut_->busclk = 1;
        sut_->eval();
    }

    void fall_sclk()
    {
        sut_->busclk = 0;
        sut_->eval();
    }

    void delay(int ticks)
    {
        for (int i = 0; i < ticks; ++i)
        {
            tick();
        }
    }

    void set_command()
    {
        sut_->command_data = 0;
    }

    void set_data()
    {
        sut_->command_data = 1;
    }

    void send_sclk()
    {
        raise_sclk();
        tick();
        tick();
        fall_sclk();
        tick();
        tick();
    }

    void send_byte(uint8_t byte)
    {
        sut_->bus_in = byte;
        send_sclk();
    }

    uint8_t get_byte()
    {
        send_sclk(); // dummy data
        send_sclk();
        return sut_->bus_out;
    }

    uint8_t get_data_byte()
    {
        uint8_t byte = sut_->data_out;
        tick();
        return byte;
    }

    std::unique_ptr<Vmcu_bus> sut_;
};

TEST_F(MCUBusTests, WriteSomeData)
{
    tick();
    sut_->bus_in = 0x01;
    send_sclk();
    constexpr int msgpu_id = 0xae;
    EXPECT_EQ(msgpu_id, get_byte());
    set_data();
    sut_->bus_in = 0x12;
    raise_sclk();
    tick();
    tick();
    fall_sclk();
    tick();
    tick();
    EXPECT_TRUE(sut_->dataclk);
    tick();
    EXPECT_FALSE(sut_->dataclk);

    EXPECT_EQ(0x12, get_data_byte());
    send_byte(0x34);
    EXPECT_EQ(0x34, get_data_byte());
}

TEST_F(MCUBusTests, WriteAddress)
{
    tick();
    sut_->bus_in = 0x02;
    set_command();
    send_sclk();
    send_byte(0x12);
    send_byte(0x34);
    send_byte(0x56);
    send_byte(0x78);
    EXPECT_EQ(0x12345678, sut_->address);
}
