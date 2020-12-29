#include "Vclock_divider.h"
#include "verilated.h"

#include <memory>

#include <gtest/gtest.h>

class ClockDividerShould : public ::testing::Test
{
public:
    ClockDividerShould() : sut_(new Vclock_divider)
    {
    }

protected:
    void raise()
    {
        sut_->clkin = 1;
        sut_->eval();
    }

    void fall()
    {
        sut_->clkin = 0;
        sut_->eval();
    }

    void tick()
    {
        sut_->clkin = 1;
        sut_->eval();
        sut_->clkin = 0;
        sut_->eval();
    }

    std::unique_ptr<Vclock_divider> sut_;
};

TEST_F(ClockDividerShould, DivideBy2)
{
    sut_->eval();
    sut_->div = 2;
    EXPECT_FALSE(sut_->clkout);
    tick();
    tick();
    raise();
    EXPECT_TRUE(sut_->clkout);
    fall();
    EXPECT_TRUE(sut_->clkout);
    tick();
    EXPECT_FALSE(sut_->clkout);
    tick();
    tick();
    raise();
    EXPECT_TRUE(sut_->clkout);
    fall();
    tick();
    tick();
    raise();
    EXPECT_FALSE(sut_->clkout);
    fall();
}

TEST_F(ClockDividerShould, DivideBy4)
{
    sut_->eval();
    sut_->div = 4;
    EXPECT_FALSE(sut_->clkout);
    raise();
    EXPECT_TRUE(sut_->clkout);
    fall();
    tick();
    raise();
    EXPECT_FALSE(sut_->clkout);
    fall();
    tick();
    raise();
    EXPECT_TRUE(sut_->clkout);
    fall();
    tick();
    raise();
    EXPECT_FALSE(sut_->clkout);
    fall();
    tick();
    raise();
    EXPECT_TRUE(sut_->clkout);
    fall();
    tick();
    raise();
    EXPECT_FALSE(sut_->clkout);
}
