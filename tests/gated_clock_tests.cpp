#include "Vgated_clock.h"
#include "verilated.h"

#include <memory>
#include <iostream>

#include <gtest/gtest.h>

class GatedClockShould : public ::testing::Test
{
public:
    GatedClockShould() : sut_(new Vgated_clock)
    {
    }

protected:
    void tick()
    {
        sut_->clock = 0;
        sut_->eval();
    }

    void raising_edge()
    {
        sut_->clock = 0;
        sut_->eval();
        sut_->clock = 1;
        sut_->eval();
    }

    void failing_edge()
    {
        sut_->clock = 1;
        sut_->eval();
        sut_->clock = 0;
        sut_->eval();
    }

    std::unique_ptr<Vgated_clock> sut_;
};

TEST_F(GatedClockShould, NotGenerateSignalWhenNotEnabled)
{
    sut_->eval();
    EXPECT_EQ(sut_->clock_output, 0);
    raising_edge();
    EXPECT_EQ(sut_->clock_output, 0);
    failing_edge();
    EXPECT_EQ(sut_->clock_output, 0);
}

TEST_F(GatedClockShould, GenerateSignalWhenEnabled)
{
    sut_->eval();
    EXPECT_EQ(sut_->clock_output, 0);
    sut_->enable = 1;
    raising_edge();
    EXPECT_EQ(sut_->clock_output, 1);
    failing_edge();
    EXPECT_EQ(sut_->clock_output, 0);
    raising_edge();
    EXPECT_EQ(sut_->clock_output, 1);
    failing_edge();
    EXPECT_EQ(sut_->clock_output, 0);
}
