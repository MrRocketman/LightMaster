<!DOCTYPE html>

<html>
    <head>
        <title>MrRocketman.com</title>
        <link href="Site.css" rel="stylesheet">
            </head>
    
    <?php require('/Applications/MAMP/htdocs/mrrocketman/Header.php'); ?>
    
    <body>
        
        <script language="javascript" type="text/javascript" src="http://mrrocketman.com/lightmaster.js"></script>
        <noscript>Please enable JavaScript to control the Christmas Lights</noscript>
        
        <div id="main">
            <h1>Welcome to MrRocketman.com</h1>
            <p>Enjoy the lights from 5:15PM to 10:30PM daily, and all night Christmas Eve.</p>
            
            <div id="output"></div>
            
            <div id="livestream">
                <h2>Livestream!</h2>
                <p>The livestream is about 30 seconds behind. I Will improve the camera angle and auidio soon!</p>
                <table>
                    <tr>
                        <td>
                            <h3>Angle 1</h3>
                        </td>
                        <td>
                            <h3>Angle 2</h3>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <iframe width="480" height="302" src="http://www.ustream.tv/embed/16713785?v=3&amp;wmode=direct" scrolling="no" frameborder="0" style="border: 0px none transparent;">    </iframe>
                            <br /><a href="http://www.ustream.tv/" style="padding: 2px 0px 4px; width: 400px; background: #ffffff; display: block; color: #000000; font-weight: normal; font-size: 10px; text-decoration: underline; text-align: center;" target="_blank">Live streaming video by Ustream</a>
                        </td>
                        <td>
                            <iframe width="480" height="302" src="http://www.ustream.tv/embed/16713791?v=3&amp;wmode=direct" scrolling="no" frameborder="0" style="border: 0px none transparent;">    </iframe>
                            <br /><a href="http://www.ustream.tv/" style="padding: 2px 0px 4px; width: 400px; background: #ffffff; display: block; color: #000000; font-weight: normal; font-size: 10px; text-decoration: underline; text-align: center;" target="_blank">Live streaming video by Ustream</a>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <h3>Angle 3</h3>
                        </td>
                        <td>
                            <h3>Angle 4</h3>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <iframe width="480" height="302" src="http://www.ustream.tv/embed/16713792?v=3&amp;wmode=direct" scrolling="no" frameborder="0" style="border: 0px none transparent;">    </iframe>
                            <br /><a href="http://www.ustream.tv/" style="padding: 2px 0px 4px; width: 400px; background: #ffffff; display: block; color: #000000; font-weight: normal; font-size: 10px; text-decoration: underline; text-align: center;" target="_blank">Live streaming video by Ustream</a>
                        </td>
                        <td>
                            <iframe width="480" height="302" src="http://www.ustream.tv/embed/16713793?v=3&amp;wmode=direct" scrolling="no" frameborder="0" style="border: 0px none transparent;">    </iframe>
                            <br /><a href="http://www.ustream.tv/" style="padding: 2px 0px 4px; width: 400px; background: #ffffff; display: block; color: #000000; font-weight: normal; font-size: 10px; text-decoration: underline; text-align: center;" target="_blank">Live streaming video by Ustream</a>
                        </td>
                    </tr>
                </table>
            </div>
            
            <div id="connection"></div>
            <div id="clients"></div>
            <h2>Control The Lights!</h2>
            <div id="boxOnOff"></div>
            <h2>Pick The Song!</h2>
            <div id="songs"></div>
            
            <div id="disqus_thread"></div>
            <script type="text/javascript">
                /* * * CONFIGURATION VARIABLES: EDIT BEFORE PASTING INTO YOUR WEBPAGE * * */
                var disqus_shortname = 'mrrocketman'; // required: replace example with your forum shortname
                
                /* * * DON'T EDIT BELOW THIS LINE * * */
                (function() {
                 var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
                 dsq.src = '//' + disqus_shortname + '.disqus.com/embed.js';
                 (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
                 })();
                </script>
            <noscript>Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript">comments powered by Disqus.</a></noscript>
            <a href="http://disqus.com" class="dsq-brlink">comments powered by <span class="logo-disqus">Disqus</span></a>
            
            <?php require('/Applications/MAMP/htdocs/mrrocketman/Footer.php'); ?>
        </div>
        
    </body>
</html>