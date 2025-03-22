CC = gcc
CFLAGS = -g
PROGRAM = leaker

.PHONY: all clean lint

all: $(PROGRAM)

# Wildcard recipe to make .o files from corresponding .cpp file
%.o: %.cpp
	$(CC) $(CFLAGS) -c $<

$(PROGRAM): main.o
	$(CC) $(CFLAGS) -o $@ $^


clean:
	rm *.o $(PROGRAM)
