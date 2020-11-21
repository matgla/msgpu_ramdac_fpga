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

    std::unique_ptr<Vclock_divider> sut_;
};

TEST_F(ClockDividerShould, DivideBy1)
{
    sut_->eval();
    sut_->div = 1;
    EXPECT_FALSE(sut_->clkout);
    raise();
    EXPECT_TRUE(sut_->clkout);
    fall();
    EXPECT_FALSE(sut_->clkout);
    raise();
    EXPECT_TRUE(sut_->clkout);
    fall();
    EXPECT_FALSE(sut_->clkout);
    raise();
    EXPECT_TRUE(sut_->clkout);
    fall();
    EXPECT_FALSE(sut_->clkout);
}

TEST_F(ClockDividerShould, DivideBy2)
{
    sut_->eval();
    sut_->div = 2;
    EXPECT_FALSE(sut_->clkout);
    raise();
    fall();
    raise();
    EXPECT_TRUE(sut_->clkout);
    fall();
    raise();
    fall();
    EXPECT_FALSE(sut_->clkout);
    raise();
    fall();
    raise();
    EXPECT_TRUE(sut_->clkout);
    fall();
    raise();
    fall();
    EXPECT_FALSE(sut_->clkout);
    raise();
    fall();
    raise();
    EXPECT_TRUE(sut_->clkout);
    fall();
    raise();
    fall();
    EXPECT_FALSE(sut_->clkout);
}

TEST_F(ClockDividerShould, DivideBy3)
{
    sut_->eval();
    sut_->div = 3;
    EXPECT_FALSE(sut_->clkout);
    raise();
    fall();
    raise();
    fall();
    raise();
    EXPECT_TRUE(sut_->clkout);
    fall();
    raise();
    fall();
    raise();
    fall();
    EXPECT_FALSE(sut_->clkout);
    raise();
    fall();
    raise();
    fall();
    raise();
    EXPECT_TRUE(sut_->clkout);
    fall();
    raise();
    fall();
    raise();
    fall();
    EXPECT_FALSE(sut_->clkout);
    raise();
    fall();
    raise();
    fall();
    raise();
    EXPECT_TRUE(sut_->clkout);
    fall();
    raise();
    fall();
    raise();
    fall();
    EXPECT_FALSE(sut_->clkout);
}
