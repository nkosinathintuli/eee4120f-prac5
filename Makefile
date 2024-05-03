PLAT=platforms
MULTI=multiplication
GOLD=multiplicationGoldenStandard

CXX=g++

# Linux OS
LIBS=-lOpenCL

CXXFLAGS= -g #-Wall -Wextra 

all: $(MULTI) $(GOLD) $(PLAT)

$(GOLD):src/goldenStandard/$(GOLD).cpp
	$(CXX) -o bin/$@ $^

$(MULTI): src/$(MULTI).cpp
	$(CXX) -o bin/$@ $^ $(LIBS)

$(PLAT):src/$(PLAT).cpp
	$(CXX) -o bin/$@ $^ $(LIBS)

gold: $(GOLD)
	./bin/$(GOLD)

multi: $(MULTI)
	./bin/$(MULTI)

plat: $(PLAT)
	./bin/$(PLAT)

clean:
	rm -f bin/$(MULTI) bin/$(GOLD)
