public class CommandLineArguments {
    public static void main(String[] args) {
        System.out.println("\nFirst Argument: "+args[0]);
        System.out.println("\nSecond Argument: "+args[1]);
        System.out.println("\nThird Argument: "+args[2]);
        System.out.println("\nFourth Argument: "+args[3]);
        System.out.println("\nFifth Argument: "+args[4]);

        //For pronting all Arguments

        int i, a=0;
        for(i=0;i<args.length;i++){
            System.out.println(args[i]);
            a=a+Integer.parseInt(args[i]);
        }
                    System.out.println("Sum of arguments is : "+a);
                    System.out.println("Average of arguments is : "+a/args.length);


    }
}
