## CYPieChart

CYPieChart is a subclass of UIView that displays your data in a pie chart.

### Preview
![Main](Images/CYPieChartMain.png)


![GIF](Images/CYPieChartGIF.gif)


### Intergration

#### Cocoapods
Simply add 

`
	use_frameworks!
`

and

` pod 'CYPieChart'
`

to your Podfile ,and Cocoapods does the magic !


#### Do it your self

Clone or download the project , drag the entire CYPieChart Folder into your project , and then :

` 
	#import "CYPieChart.h"
`

,and you are ready to go.


### Usage

To use CYPieChart ,your code would be something like this:
<pre>
<code>
	for (NSUInteger i = 0; i < count; ++i) 
	{
        PieChartDataObject *obj = [[PieChartDataObject alloc] initWithTitle:@"String Representation Of Your Data" value: value of your data]; 
        [objectArray addObject:obj];
    }
    for (NSUInteger i = 0; i < count; ++i) {
        [colorArray addObject:UIColor Object];
    }
	self.pieChart.objects = objectArray;
	self.pieChart.colors = colorArray;
	[self.pieChart updateAppearance];
</code>
</pre>

You specify what data the chart is going to present along with the colors that it uses presenting those data , you can also set other properties such as `moveRadius` ,` titlePosition` to customize the appearance of the chart. At last , you MUST call `[pieChart updateAppearance]` to notify the pie chart to update its appearance.

For more detail ,plz clone or download the zip and view the sample project.

If there is any problems / suggestions ,I'll be very grateful to hear from you!