# install cython
result=$(pip3 freeze|grep Cython)
if [ "$result" != "Cython==0.29.6"]; then
    pip3 install cython
fi

# install gmatch4py
cd ../bin
# git clone https://github.com/Jacobe2169/GMatch4py.git
cd GMatch4py
pip3 install .
cd ../..

