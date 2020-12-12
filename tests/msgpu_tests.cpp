#include "Vmsgpu.h"
#include "verilated.h"

#include <memory>

#include <gtest/gtest.h>
#include <gmock/gmock.h>

class MsgpuShould : public ::testing::Test
{
public:
    MsgpuShould() : tick_counter(0), sut_(new Vmsgpu)
    {
    }

protected:
    using line_type = std::vector<uint16_t>;
    using frame_type = std::vector<line_type>;

    uint64_t tick_counter;
    void tick()
    {
        sut_->clock = 0;
        sut_->eval();
        sut_->mcu_bus = bus_state_;
        sut_->clock = 1;
        sut_->eval();
        ++tick_counter;
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
        sut_->mcu_bus_clock = 0;
        tick();
        tick();
    }

    void send_byte(uint8_t byte) 
    {
        bus_state_ = byte;
        sut_->mcu_bus_command_data = 1;
        generate_sclk();
    }

    void send_u16(uint16_t data)
    {
        send_byte((data >> 4) & 0xff);
        send_byte(data & 0xff);
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

    void send_vga_tick()
    {
        for (int i = 0; i < 8; ++i)
        {
            tick();
        }
    }

    void synchronize_clock(uint8_t clock)
    {
        while (tick_counter % (clock - 1)) 
        {
            tick();
        }
    }

    void vga_line()
    {
        for (int i = 0; i < 800; i++)
        {
            send_vga_tick();
        }
    }

    uint16_t get_pixel()
    {
        uint16_t data = sut_->vga_red << 8 | sut_->vga_green << 4 | sut_->vga_blue;
        return data; 
    }

    line_type generate_line(uint16_t starting_pixel, size_t length) const
    {
        line_type line(length);
        std::generate(line.begin(), line.end(), [&starting_pixel](){
            return starting_pixel++;
        });
        return line;
    }

    void send_line(const line_type& line) 
    {
        for (uint16_t pixel : line) 
        {
            send_u16(pixel);
        }
    }

    void send_frame(const frame_type& frame)
    {
        for (const auto& line : frame)
        {
            send_line(line);
        }
    }


    line_type get_line() 
    {
        line_type line(640);
        for (int i = 0; i < 640; ++i)
        {
            send_vga_tick();
            line[i] = get_pixel();
        }
        // front porch 
        for (int i = 0; i < 16; ++i) 
        {
            send_vga_tick();
        }
        // sync pulse  
        EXPECT_FALSE(sut_->hsync);
        for (int i = 0; i < 96; ++i) 
        {
            send_vga_tick();
        }
        // back porch
        EXPECT_TRUE(sut_->hsync);
        for (int i = 0; i < 48; ++i)
        {
            send_vga_tick();
        }
        return line; 
    }

    frame_type get_frame()
    {
        frame_type frame(480);
        for (uint16_t line = 0; line < 480; ++line)
        {
            frame[line] = get_line();
        }
        return frame; 
        // handle vsync 
    }


    frame_type generate_frame()
    {
        frame_type frame(480);
        for (auto& line : frame) 
        {
            line.reserve(640);
        }
       
        uint16_t starting_pixel = 0;
        for (int i = 0; i < 480; i++)
        {
            if (starting_pixel > 3000) 
            {
                starting_pixel -= 3000;
            }
            frame[i] = generate_line(starting_pixel, 640);
            starting_pixel += 480;
        }
        return frame;
    }

    uint8_t bus_state_;
    std::unique_ptr<Vmsgpu> sut_;
};

TEST_F(MsgpuShould, WriteDataToPsram)
{
    tick();
    set_address(0xdeadbeef);
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
    tick();
    tick();
}

TEST_F(MsgpuShould, SendDataToPsram)
{
    tick();
    
    auto frame = generate_frame();
    send_frame(frame);
    send_vga_tick();
    send_vga_tick();
    send_command(0x02);
    synchronize_clock(8); // synchronize to vga clock
    send_vga_tick(); // 1 tick delay
    auto displayed_frame = get_frame();
    for (int i = 0; i < 480; i++)
    {
        EXPECT_THAT(frame[i], ::testing::ElementsAreArray(displayed_frame[i]));
    }
}
