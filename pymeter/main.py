from pymeter.api.config import TestPlan, ThreadGroupSimple, ThreadGroupWithRampUpAndHold
from pymeter.api.samplers import HttpSampler
import time

start = time.perf_counter()
'''
POST REQUEST EXAMPLE
http_sampler = (
    HttpSampler("echo_get_request", "https://postman-echo.com/get?var=1")
    .header("SomeKey", "some_value")
    .post({"var1": 1}, ContentType.APPLICATION_JSON)
)
'''
# create HTTP sampler, sends a get request to the given url
url = "https://smp.ppdbsurabaya.net/"
http_sampler = HttpSampler("echo_get_request", url)

thread = 100
holdup = 10
rampup_sec = 1
i = 0
start = ''
end = ''
times = []
while True:

    # create a thread group with 10 threads that runs for 1 iterations, give it the http sampler as a child input
    thread_group = ThreadGroupWithRampUpAndHold(thread, rampup_sec, holdup, http_sampler)

    # create a test plan with the required thread group
    test_plan = TestPlan(thread_group)

    '''
    Thread and iter logic here
    i = i+1
    thread = thread + 100
    '''

    # run the test plan and take the results
    start = time.perf_counter()
    stats = test_plan.run()
    end = time.perf_counter()

'''
1 detik ngirim {thread} request
nunggu batch selesai
nambah iterasi, sesuaikan jumlah thread dengan iterasi
test lagi
'''