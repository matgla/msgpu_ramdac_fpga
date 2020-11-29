#include "Vpsram.h"
#include "verilated.h"

#include <memory>
#include <iostream>

#include <gtest/gtest.h>

constexpr uint8_t reset_enable_command = 0x66;
constexpr uint8_t reset_command = 0x99;
constexpr uint8_t read_id_command = 0x9f;

class PSRAMShould : public ::testing::Test
{
public:
    PSRAMShould() : sut_(new Vpsram)
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

    void delay(int ticks)
    {
        for (int i = 0; i < ticks; ++i)
        {
            tick();
        }
    }

    constexpr uint8_t get_bit(uint8_t byte, int bit)
    {
        if (byte & (1 << bit))
        {
            return 1;
        }
        return 0;
    }

    constexpr uint8_t set_bit(uint8_t& byte, int bit, int value)
    {
        byte &= ~(1 << bit);
        byte |= (value << bit);
        return byte;
    }

    uint8_t interchange_bit(uint8_t bit)
    {
        set_bit(sut_->psram_sio_in, 1, bit);
        tick();
        return get_bit(sut_->psram_sio_out, 0);
    }

    uint8_t interchange_byte(uint8_t byte)
    {
        uint8_t rx_byte = 0;
        rx_byte |= interchange_bit(get_bit(byte, 7)) << 7;
        EXPECT_TRUE(sut_->psram_sclk);
        rx_byte |= interchange_bit(get_bit(byte, 6)) << 6;
        rx_byte |= interchange_bit(get_bit(byte, 5)) << 5;
        rx_byte |= interchange_bit(get_bit(byte, 4)) << 4;
        rx_byte |= interchange_bit(get_bit(byte, 3)) << 3;
        rx_byte |= interchange_bit(get_bit(byte, 2)) << 2;
        rx_byte |= interchange_bit(get_bit(byte, 1)) << 1;
        rx_byte |= interchange_bit(get_bit(byte, 0)) << 0;
        tick(); // change state
        EXPECT_FALSE(sut_->psram_sclk);
        return rx_byte;
    }

    void initialize()
    {
        delay(2004);
        tick();
        { // Receive reset enable command
            EXPECT_TRUE(sut_->psram_ce_n);
            const uint8_t reset_enable = interchange_byte(0xff);
            EXPECT_EQ(reset_enable, reset_enable_command);
            delay(1);
            EXPECT_FALSE(sut_->psram_ce_n);
        }
        delay(1);
        {
            EXPECT_EQ(reset_command, interchange_byte(0xff));
        }
        delay(3);
        {
            EXPECT_EQ(read_id_command, interchange_byte(0xff));
            constexpr uint8_t dummy_address = 0xff;
            EXPECT_EQ(dummy_address, interchange_byte(0xff));
            EXPECT_EQ(dummy_address, interchange_byte(0xff));
            EXPECT_EQ(dummy_address, interchange_byte(0xff));

            constexpr uint8_t mfid = 0x0d;
            interchange_byte(mfid);
            delay(1);
            constexpr uint8_t passed_kgd = 0x5d;
            interchange_byte(passed_kgd);
            delay(1);
            constexpr uint8_t eid = 0xff;
            interchange_byte(eid);
            delay(1);
            interchange_byte(eid);
            delay(1);
            interchange_byte(eid);
            delay(1);
            interchange_byte(eid);
            delay(1);
            interchange_byte(eid);
            delay(1);
            interchange_byte(eid);
            delay(3);
            EXPECT_TRUE(sut_->psram_ce_n);
        }
        delay(1); // print
    }

    std::unique_ptr<Vpsram> sut_;
};

TEST_F(PSRAMShould, InitializeDefaults)
{
    sut_->eval();
    sut_->enable = 1;
    sut_->eval();
}

TEST_F(PSRAMShould, InitializeDriverAfterTimeout)
{
    delay(2004);
    tick();
    { // Receive reset enable command
        EXPECT_TRUE(sut_->psram_ce_n);
        const uint8_t reset_enable = interchange_byte(0xff);
        EXPECT_EQ(reset_enable, reset_enable_command);
        delay(1);
        EXPECT_FALSE(sut_->psram_ce_n);
    }
    delay(1);
    {
        EXPECT_EQ(reset_command, interchange_byte(0xff));
    }
    delay(3);
    {
        EXPECT_EQ(read_id_command, interchange_byte(0xff));
        constexpr uint8_t dummy_address = 0xff;
        EXPECT_EQ(dummy_address, interchange_byte(0xff));
        EXPECT_EQ(dummy_address, interchange_byte(0xff));
        EXPECT_EQ(dummy_address, interchange_byte(0xff));

        constexpr uint8_t mfid = 0x0d;
        interchange_byte(mfid);
        delay(1);
        constexpr uint8_t passed_kgd = 0x5d;
        interchange_byte(passed_kgd);
        delay(1);
        constexpr uint8_t eid = 0xff;
        interchange_byte(eid);
        delay(1);
        interchange_byte(eid);
        delay(1);
        interchange_byte(eid);
        delay(1);
        interchange_byte(eid);
        delay(1);
        interchange_byte(eid);
        delay(1);
        interchange_byte(eid);
        delay(3);
        EXPECT_TRUE(sut_->psram_ce_n);
    }
    delay(1); // print
}

TEST_F(PSRAMShould, WriteData)
{
    initialize();
    sut_->set_address = 1;
    sut_->address = 0x1beef1;
    sut_->data = 0xab;
    tick();
    tick();
    sut_->set_address = 0;
    tick();
    tick();
    tick();
    tick();
    tick();
    tick();
    tick();
    tick();
    tick();
    tick();
    tick();
    tick();
    tick();
    tick();
    tick();
    tick();
    tick();
}
