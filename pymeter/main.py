from pymeter.api.config import TestPlan, ThreadGroupSimple, ThreadGroupWithRampUpAndHold
from pymeter.api.samplers import HttpSampler
from pymeter.api.reporters import HtmlReporter
import time
from pymeter.api.timers import ConstantTimer

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

# thread = 100
holdup = 600
rampup_sec = 1
i = 0
start = ''
end = ''
times = list()
timer = ConstantTimer(0)
threads = [1000, 5000, 10000, 20000]
# threads = [100]
for thread in threads:
    print('.')
    html_reporter = HtmlReporter()
    # create a thread group with {thread} threads that runs for for 600 sec, give it the http sampler as a child input
    thread_group = ThreadGroupWithRampUpAndHold(thread, rampup_sec, holdup, http_sampler, timer)

    # create a test plan with the required thread group
    test_plan = TestPlan(thread_group, html_reporter)

    # run the test plan and take the results
    start = time.perf_counter()
    stats = test_plan.run()
    end = time.perf_counter()
    timer = ConstantTimer(10000)
    times.append(end-start)