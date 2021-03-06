// This file is part of MSGPU project.
// Copyright (C) 2020 Mateusz Stadnik
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

#ifndef IMAGE_LOADER_H
#define IMAGE_LOADER_H

#include <cstdint>
#include <string>
#include <vector>

#include <SFML/Graphics.hpp>

class ImageLoader
{
public:
    struct Config 
    {
        int width;
        int height;
        int frames_in_row;
        int frames_in_column;
    };

    using Line = std::vector<uint16_t>;
    using Frame = std::vector<Line>;
    
    ImageLoader(const std::string& path, Config config);

    Frame get_frame(int number) const;

private:
    Config config_;
    sf::Image image_; 
};

#endif /* IMAGE_LOADER_H */

