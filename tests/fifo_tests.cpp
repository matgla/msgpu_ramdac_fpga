#include "Vfifo_tb.h" 
#include "verilated.h" 

#include <memory> 

#include <gtest/gtest.h> 

/* 12 bit width */
class FifoShould : public ::testing::Test 
{
public: 
    FifoShould() 
    {
    }

protected: 
    void write_data(uint16_t data)
    {
        sut_.input_data = data; 
        sut_.write_clock = 1;
        sut_.eval(); 
        sut_.write_clock = 0; 
        sut_.eval();
    }

    uint16_t read_data()
    {
        uint16_t data; 
        sut_.read_clock = 1;
        sut_.eval(); 
        data = sut_.output_data;
        sut_.read_clock = 0; 
        sut_.eval();
        return data;
    }
    Vfifo_tb sut_;
};

TEST_F(FifoShould, ReportEmpty) 
{
    sut_.eval();
    write_data(0xfff);
    write_data(0x111);
    write_data(0xaa2); 

    EXPECT_EQ(read_data(), 0xfff);
    EXPECT_EQ(read_data(), 0x111);
    EXPECT_EQ(read_data(), 0xaa2);
    EXPECT_EQ(read_data(), 0x000);
    EXPECT_EQ(read_data(), 0x000);

    write_data(0x234);
    write_data(0x121);
    EXPECT_EQ(read_data(), 0x234);
    EXPECT_EQ(read_data(), 0x121);
}
