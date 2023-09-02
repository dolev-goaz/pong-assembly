CC = nasm
CFLAGS = -f elf64 -g

SRC_DIR = asm
OBJ_DIR = obj

# List all assembly source files
SRCS = $(wildcard $(SRC_DIR)/*.asm)

# Generate the corresponding object file names
OBJS = $(patsubst $(SRC_DIR)/%.asm, $(OBJ_DIR)/%.o, $(SRCS))

# Ensure the OBJ_DIR directory exists or create it
$(shell mkdir -p $(OBJ_DIR))

game: $(OBJS)
	gcc -o game $(OBJS) -lX11 -no-pie -e main

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.asm
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -r $(OBJ_DIR)
