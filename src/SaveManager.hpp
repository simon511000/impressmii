#pragma once

#include <nlohmann/json.hpp>
#include <string>
#include <stdexcept>

using json = nlohmann::json;

class SaveManager {
public:
    SaveManager(const std::string &path);

    void load(json &j);

    void save(const json &j);

private:
    std::string filePath;
};