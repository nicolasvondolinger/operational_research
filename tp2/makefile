CC = g++
CFLAGS = -O3
TARGET = main
TESTER = python tester.py
OUTPUT = out.txt

all: compile test

compile:
	$(CC) $(CFLAGS) main.cpp -o $(TARGET)

test:
	$(TESTER)

clean:
	rm -f $(TARGET) $(OUTPUT)

.PHONY: all compile test clean