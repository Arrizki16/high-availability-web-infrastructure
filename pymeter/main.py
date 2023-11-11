from pymeter.api.config import TestPlan, ThreadGroupWithRampUpAndHold
from pymeter.api.samplers import HttpSampler
from pymeter.api.reporters import HtmlReporter
from pymeter.api import ContentType
from pymeter.api.timers import ConstantTimer

'''
100 thread -> 1200 req / detik -> 2 instance (cpu utilization +- 40% total)
500 thread -> 6000 req / detik -> 10 instance
'''
# create HTTP sampler, sends a get request to the given url
url = "http://load-balancer-74252051.ap-southeast-1.elb.amazonaws.com"
endpoint_paths = ["/api/version", "/api/user", "/api/user/1", "/api/image", "/api/1/images"]

holdup = 300
rampup_sec = 1

times = list()
timer = ConstantTimer(0)
threads = [100, 200, 500]

for endpoint_path in endpoint_paths:
    for thread in threads:
        if endpoint_path == "/api/user":
            # logic for user login
            http_sampler = (HttpSampler("login_post_request", url + endpoint_path)
                .post({
                        "email": "yanzkosim@gmail.com",
                        "password": "yanzkosim"
                    }, ContentType.APPLICATION_JSON)
                )
        elif endpoint_path == "/api/image":
            #logic for upload image
            http_sampler = (HttpSampler("upload_post_request", url + endpoint_path)
                .multipart("image", "image2.jpg", ContentType.MULTIPART_FORM_DATA)
                )
        else:
            http_sampler = HttpSampler("get_request", url + endpoint_path)

        print(f'Processing number of user: {thread}, endpoint: {url+endpoint_path}')
        html_reporter = HtmlReporter()
        # create a thread group with {thread} threads that runs for for 600 sec, give it the http sampler as a child input
        thread_group = ThreadGroupWithRampUpAndHold(thread, rampup_sec, holdup, http_sampler, timer)

        # create a test plan with the required thread group
        test_plan = TestPlan(thread_group, html_reporter)

        # run the test plan and take the results
        stats = test_plan.run()
        timer = ConstantTimer(10000)

# http_sampler = (HttpSampler("echo_get_request", url + endpoint_paths[3])
#                 .multipart("image", "image2.jpg", ContentType.MULTIPART_FORM_DATA)
#                 )
# html_reporter = HtmlReporter()
# thread_group = ThreadGroupWithRampUpAndHold(10, rampup_sec, 10, http_sampler, timer)
# test_plan = TestPlan(thread_group, html_reporter)
# stats = test_plan.run()