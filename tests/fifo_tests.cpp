#include "Vfifo.h"
#include "verilated.h"

#include <memory>

#include <gtest/gtest.h>

class FifoTests : public ::testing::Test
{
public:
    FifoTests() : sut_(new Vfifo)
    {
    }

protected:
    void tick()
    {
        sut_->clockin = 0;
        sut_->eval();
        sut_->clockin = 1;
        sut_->eval();
    }

    void push(uint8_t data)
    {
        sut_->datain = data;
        sut_->datain_enable = 1;
        tick();
        sut_->datain_enable = 0;
    }

    uint8_t pop()
    {
        sut_->dataout_enable = 1;
        tick();
        uint8_t data = sut_->dataout;
        sut_->dataout_enable = 0;
        return data;
    }

    void reset()
    {
        sut_->reset = 1;
        tick();
        sut_->reset = 0;
    }

    std::unique_ptr<Vfifo> sut_;
};

TEST_F(FifoTests, PerformNormalUsage)
{
    reset();
    EXPECT_TRUE(sut_->empty);
    EXPECT_FALSE(sut_->full);
    
    push(0xaa);
    EXPECT_FALSE(sut_->empty);
    push(0xbb);

    EXPECT_EQ(0xaa, pop());
    EXPECT_EQ(0xbb, pop());
    EXPECT_TRUE(sut_->empty);
    EXPECT_EQ(0x00, pop());
    EXPECT_TRUE(sut_->empty);
    EXPECT_EQ(0x00, pop());
    push(0x11);
    EXPECT_FALSE(sut_->empty);
    EXPECT_EQ(0x11, pop());
}

TEST_F(FifoTests, ReachFull)
{
    reset();
    push(0x01);
    push(0x02);
    push(0x03);
    EXPECT_FALSE(sut_->full);
    push(0x04);
    EXPECT_TRUE(sut_->full);
    push(0x05);
    push(0x06);
    EXPECT_EQ(0x01, pop());
    EXPECT_FALSE(sut_->full);
    EXPECT_EQ(0x02, pop());
    push(0x05);
    EXPECT_EQ(0x03, pop());
    EXPECT_EQ(0x04, pop());
    EXPECT_EQ(0x05, pop());
    EXPECT_TRUE(sut_->empty);
    EXPECT_EQ(0x0, pop());
}